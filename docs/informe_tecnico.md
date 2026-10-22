# Informe Técnico — Proyecto Extracción PDF

Trabajo Práctico: *Test de Carga, Estrés y Optimización de Microservicio*.

Este informe describe la arquitectura del sistema, las decisiones de diseño, el
proceso de investigación del cuello de botella y las optimizaciones aplicadas,
con las mediciones pendientes de volcar en la §6. **No contiene cifras de
rendimiento inventadas**: las tablas de resultados están vacías por diseño y se
completan ejecutando el runbook manual (`audit/audit-benchmark.md` §8).

## 1. Arquitectura del Sistema

Arquitectura de microservicios orquestada con Docker Compose y Traefik como API
gateway y balanceador: **Traefik → API → Extraction & Persistence → MongoDB**.

```
Host :80/:443 ──► Traefik v3 (:80 redirect → :443, TLS mkcert)
                    │ red `services`
                    ├─► api        :8000  (solo red interna; Host pdf-extractext.localhost)
                    │     ├─► EXTRACTION_URL  = http://traefik:8090  (entrypoint interno)
                    │     └─► PERSISTENCE_URL = http://persistence:8002
                    ├─► extraction :8001  (réplicas 1..5; Host extraction.pdf-extractext.localhost)
                    └─► persistence:8002 ─── red `data` ───► mongodb :27017 (no publicado)
```

Tres servicios de aplicación con responsabilidades separadas:

- **API** (Go / Fiber sobre fasthttp): único borde público. Expone `POST /extract`
  (proxy stateless hacia Extraction), `POST /upload-pdf` (orquesta extracción +
  persistencia) y el CRUD `/documents`.
- **Extraction** (Python / FastAPI + Gunicorn/Uvicorn): convierte el PDF a
  Markdown con PyMuPDF. Es el recurso intensivo en CPU y el único servicio que
  escala horizontalmente.
- **Persistence** (Go / chi): acceso exclusivo a MongoDB, con índice único
  `checksum_1` como única fuente anti-duplicados.

Dos redes aíslan el flujo de datos:

- **Red `services`**: Traefik, API, Extraction y Persistence; todos se comunican entre sí.
- **Red `data`**: solo MongoDB y Persistence. Únicamente Persistence accede a la
  base, lo que reduce la superficie de ataque y concentra la validación de datos.

Cada contenedor tiene límite explícito de CPU y memoria (ADR D9), base del
escalado horizontal controlado:

| Servicio | cpus | memoria | Réplicas |
|---|---|---|---|
| traefik | 0.5 | 512M | 1 |
| api | 1.0 | 512M | 1 |
| extraction | 1.0 | 1G | `EXTRACTION_REPLICAS` (1–5) |
| persistence | 1.0 | 512M | 1 |
| mongodb | 1.0 | 1G | 1 |

## 2. Justificación de Decisiones Arquitectónicas Clave

### 2.1 Traefik como API Gateway y Balanceador (D1, D3, D17, D19)

- **Integración nativa con Docker:** auto-descubre los servicios por labels y
  actualiza rutas y balanceo al iniciar o detener contenedores, sin
  reconfiguración manual.
- **Configuración declarativa:** las rutas se definen como labels de Compose,
  fáciles de versionar y revisar.
- **Gestión de TLS:** centraliza los certificados (mkcert en desarrollo) y la
  redirección HTTP → HTTPS.
- **Dos entrypoints:** `:80`/`:443` públicos (solo la API) y un entrypoint
  `internal` en `:8090`, **no publicado** al host, para el tráfico entre
  servicios (API → Extraction). El dashboard de Traefik se restringe a este
  entrypoint interno y no se expone en el borde (D1, `FIND-036`).
- **Restricciones aceptadas por diseño:** el borde no declara healthcheck HTTP
  propio ni `forwardingTimeouts` (D19, `FIND-035`); la exclusión de réplicas
  degradadas la hace el healthcheck de Docker y los timeouts efectivos los
  impone el cliente de la API. El nombre de proyecto es fijo (D17).

### 2.2 Escalabilidad horizontal de Extraction (D3, D9)

Extraction se escala de 1 a 5 réplicas con `EXTRACTION_REPLICAS` (validado en
`make check`). Como cada réplica es un proceso stateless sin puertos publicados
ni volúmenes, el escalado no requiere coordinación: Traefik reparte el tráfico
round-robin entre las réplicas healthy. Esta es la **palanca principal** del TP
(sección *Estrategia de réplicas y Balanceo*).

### 2.3 Saturación: backpressure con HTTP 503 (D10)

Al superar `MAX_CONCURRENCY` por réplica, el `AdmissionMiddleware` de Extraction
rechaza de inmediato con **503 + `Retry-After`** (code `SERVICE_OVERLOADED`),
**fail-fast**: no se acumulan solicitudes que terminarían en timeout. Es el
control de admisión real del sistema; la API no tiene rate-limit propio (el
rechazo efectivo lo produce Extraction, escalable 1→5 réplicas).

### 2.4 Contrato de Extraction (D14)

Entrada **únicamente** `multipart/form-data` con campo `file` (streaming por
`io.Pipe` en la API, sin volcar a disco). Salida 200 con
`{"content": "...", "page_count": N}`. El SHA-256 lo calcula Extraction y la API
lo reenvía a Persistence para el índice único `checksum_1`.

### 2.5 Errores unificados: RFC 9457 (D16)

Los tres servicios responden `application/problem+json` con `type` (URN),
`title`, `status`, `detail` y el miembro de extensión `code`. La API **propaga**
los 4xx y el 503 del extractor tal cual (conservando `Retry-After`) y solo
genera 502 para fallos de red/timeout o respuestas 500 del upstream. Se eliminó
el envelope legacy `{"error": "..."}`.

## 3. Análisis del Cuello de Botella e Investigación

El objetivo del TP es sostener un **spike de 100 VUs** (k6, modelo cerrado) y una
**carga abierta de 50 req/s** (Vegeta) sin degradar latencias ni generar
timeouts. El cuello de botella se identificó y atacó en dos frentes: la
**concurrencia por réplica** y el **coste de CPU de la extracción**.

### 3.1 Capacidad por réplica

Extraction corre Gunicorn con **1 worker × 1 slot** (`WEB_CONCURRENCY=1`,
`MAX_CONCURRENCY=1`). La extracción concurrente del sistema es por tanto
`réplicas (1–5) × 1 × 1` = **1 a 5 peticiones simultáneas**, con un backlog de
64 conexiones por réplica. Con una sola réplica, un pico de carga llevaba su CPU
al 100 % sostenido, con latencias altas y rechazos 503. La salida natural,
alineada con el TP, es la **paralelización horizontal** (§2.2).

### 3.2 Coste de la extracción (medición A/B)

Mediciones locales sobre el corpus oficial (mismo host, misma corrida; los
tiempos absolutos son orientativos, los *ratios* son el hallazgo):

- **Decodificación de imágenes descartadas (`FIND-016`):** `get_text("dict")`
  decodificaba las imágenes que luego se descartaban. Al excluir
  `TEXT_PRESERVE_IMAGES`, el coste de la página pesada bajó de **6,67 s a
  0,32 s** (~20×) sin cambiar la salida Markdown (idéntica byte a byte en los 5
  PDFs de prueba).
- **Bloqueo del event loop (`FIND-017`):** la extracción CPU-bound corría como
  código síncrono dentro del endpoint `async def`, bloqueando el event loop
  (se midió `/health` retrasado **11,6 s**). Delegarla a `run_in_threadpool`
  libera el loop: el rechazo 503 pasa a alcanzar también a las solicitudes
  encoladas.
- **Ratio dict/plano:** `get_text("dict")` costaba hasta 19,5× el modo plano en
  el PDF pesado, y 1,6× en el PDF liviano — fuerte dependencia del documento.

### 3.3 Corpus y varianza

El corpus son **4 PDFs oficiales** con hashes únicos, pero **muy dispares**
(319 KB → 8,9 MB; 16 → 90 páginas; 0 → 91 imágenes). El PDF más caro es ~28× el
más liviano, por lo que los percentiles mezclan documentos baratos y caros: hay
que documentar el corpus efectivo en cada corrida (`FIND-050`).

## 4. Optimizaciones Aplicadas

Todas las optimizaciones están implementadas y verificadas con suites de tests;
las corridas de carga quedan pendientes (§6).

| Área | Cambio | Evidencia |
|---|---|---|
| CPU de extracción | `get_text("dict")` sin `TEXT_PRESERVE_IMAGES` (~20× en la página pesada, salida idéntica) | `FIND-016`; `domain/extractor.py`; `make test` → 76 passed, 1 xfailed |
| Concurrencia | Extracción en `run_in_threadpool`; `/health` y el 503 no se bloquean | `FIND-017`; `tests/api/test_concurrency.py` (2 tests) |
| Memoria / robustez | Spool del `UploadFile` liberado tras leer; PDF cifrado → 422 `INVALID_PDF_CONTENT` | `FIND-018`/`FIND-019` (parcial) |
| Config. de arranque | Defaults de workers del extractor alineados a 1 (ADR 0002); puerto muerto eliminado | `FIND-021`/`FIND-022` |
| Cliente HTTP de la API | `Transport` con keep-alive explícito (`MaxIdleConnsPerHost=100`, `IdleConnTimeout`) | `FIND-024` |
| Timeouts de servidor | `ReadTimeout`/`WriteTimeout`/`IdleTimeout` en Fiber y `http.Server` | `FIND-025` |
| Detección de timeout | `isTimeout` unificado → 504 `GATEWAY_TIMEOUT` | `FIND-031` |
| Límite de entrada | `MAX_FILE_SIZE_MB=16` (bajo el umbral de spool de fasthttp) | `FIND-030` |
| Prop. de errores | 4xx/503 del extractor propagados con `Retry-After`; RFC 9457 en los 3 servicios | `FIND-012`/`FIND-015`; D16 |
| Correlación | `X-Request-ID` generado y propagado a todos los upstreams | `FIND-014` |
| Contenedores | API y Persistence nonroot; `stop_grace_period` 35 s (extraction) / 15 s | `FIND-032`/`FIND-033`/`FIND-034` |
| Superficie de ataque | Dashboard de Traefik restringido al entrypoint interno | `FIND-036` |
| Validación de contratos | `/extract` rechaza respuesta incompleta del extractor (502); `EXTRACTION_HOST` configurable | `INT-01` |
| Persistencia | `POST /documents` valida invariantes (400/422) | `INT-02`; tests de contrato |

### 4.1 Investigación de la configuración final

El proceso fue iterativo: (1) caracterizar el corpus y medir el coste de la
extracción por bandera; (2) aislar los dos cuellos de botella —decodificación de
imágenes y event loop bloqueado— y corregirlos con el menor cambio de contrato
posible; (3) confirmar que las correcciones no alteran la salida Markdown
(identidad byte a byte); (4) medir la capacidad resultante (1–5 slots) y
verificar los límites efectivos de contenedor con `docker inspect`; y
(5) corregir los scripts de carga para que sus perfiles coincidan con el
enunciado (k6 100 VUs, Vegeta 50 req/s, formato de targets y extracción de
métricas). El detalle completo está en `audit/audit-findings.md` y
`audit/audit-benchmark.md`.

## 5. Contratos e Integración (resumen)

| Interfaz | Contrato |
|---|---|
| API → Extraction (`POST /extract`) | multipart `file`; 200 `{content, page_count}`; 4xx/503 propagados; 502 para red/timeout/500/C1 incompleto |
| API → Persistence (`/documents`) | JSON; 201/200/204; 400/404/409 mapeados; `X-Request-ID` propagado |
| Persistence → MongoDB | driver oficial; índice único `checksum_1`; anti-TOCTOU por duplicate-key → 409 |
| Traefik → servicios | TLS `:443` para la API; entrypoint `internal :8090` para Extraction (no publicado) |

Detalle de la matriz `INT-01`…`INT-04` en `audit/audit-master.md` §4.

## 6. Comparativa de Métricas (pendiente de corridas)

> **Estado:** los scripts de carga están **corregidos y validados** (`FIND-003`,
> `FIND-007`, `FIND-048`, `FIND-049`, `FIND-053`, `FIND-054`): perfil k6 =
> 100 VUs (40 s, con `handleSummary()`) y Vegeta = 50 req/s × 30 s (targets en
> `-format=json`, timeout 30 s), ambos ensayados contra el mock del repo.
> **Las corridas reales sobre el stack siguen pendientes de ejecución**, por lo
> que las tablas están **vacías por diseño**: no se presentan cifras no medidas.
> Para completarlas, seguir el runbook `audit/audit-benchmark.md` §8 y volcar los
> resultados en esta sección.

### 6.1 Escenario Base — k6 Spike, 1 réplica

- **Configuración:** `EXTRACTION_REPLICAS=1`; 1 CPU / 1 GB por réplica.
- **Perfil k6:** 0 → 100 VUs en 10 s; 20 s a 100 VUs; bajada a 0 en 10 s (40 s).

| Métrica | Valor | Unidad | Observaciones |
| :--- | :--- | :--- | :--- |
| Peticiones procesadas | — | req | pendiente de medición |
| Throughput | — | req/s | pendiente de medición |
| Tasa de error | — | % | pendiente de medición |
| Latencia p50 | — | s | pendiente de medición |
| Latencia p90 | — | s | pendiente de medición |
| Latencia p95 | — | s | pendiente de medición |
| Latencia máxima | — | s | pendiente de medición |

### 6.2 Escenario Base — Vegeta, 1 réplica

- **Configuración:** `EXTRACTION_REPLICAS=1`; 1 CPU / 1 GB por réplica.
- **Perfil Vegeta:** 50 req/s × 30 s (1.500 reqs), timeout cliente 30 s, round-robin de los 4 PDFs.

| Métrica | Valor | Unidad | Observaciones |
| :--- | :--- | :--- | :--- |
| Throughput efectivo | — | req/s | pendiente de medición |
| Peticiones exitosas | — | req / % | pendiente de medición |
| Timeouts de cliente (código 0) | — | req / % | pendiente de medición |
| Respuestas 503 (backpressure) | — | req / % | pendiente de medición |
| Latencia P50 | — | s | pendiente de medición |

### 6.3 Escenario Optimizado — k6 Spike, 5 réplicas

- **Configuración:** `EXTRACTION_REPLICAS=5`; 1 CPU / 1 GB por réplica.

| Métrica | Valor | Unidad | Observaciones |
| :--- | :--- | :--- | :--- |
| Peticiones procesadas | — | req | pendiente de medición |
| Throughput | — | req/s | pendiente de medición |
| Tasa de error | — | % | pendiente de medición |
| Latencia p50 | — | s | pendiente de medición |
| Latencia p90 | — | s | pendiente de medición |
| Latencia p95 | — | s | pendiente de medición |
| Latencia máxima | — | s | pendiente de medición |

### 6.4 Escenario Optimizado — Vegeta, 5 réplicas

- **Configuración:** `EXTRACTION_REPLICAS=5`; 1 CPU / 1 GB por réplica.

| Métrica | Valor | Unidad | Observaciones |
| :--- | :--- | :--- | :--- |
| Throughput efectivo | — | req/s | pendiente de medición |
| Peticiones exitosas | — | req / % | pendiente de medición |
| Timeouts de cliente (código 0) | — | req / % | pendiente de medición |
| Respuestas 503 (backpressure) | — | req / % | pendiente de medición |
| Latencia P50 | — | s | pendiente de medición |

### 6.5 Comparativa vs Referencia del Profesor

Referencia de la cátedra (`audit/audit-benchmark.md` §3, `[DOCUMENTADO-NO-VERIFICADO]`):

| Prueba | Métrica | Referencia cátedra | Medición propia (1 réplica) | Medición propia (5 réplicas) |
| :--- | :--- | :--- | :--- | :--- |
| k6 Spike | Requests | 1.037 | — | — |
| k6 Spike | Throughput | 25,35 req/s | — | — |
| k6 Spike | Tasa de error | 0,00 % | — | — |
| k6 Spike | P50 / P90 / P95 | 1,88 / 7,83 / 8,80 s | — | — |
| k6 Spike | Máximo | 13,94 s | — | — |
| Vegeta | Throughput efectivo | 16,65 req/s | — | — |
| Vegeta | Exitosas | 998 / 1.500 (66,53 %) | — | — |
| Vegeta | Timeouts | 501 (33,40 %) | — | — |
| Vegeta | P50 | 14,89 s | — | — |

### 6.6 Evidencia de infraestructura (a adjuntar)

Junto con las tablas, adjuntar por corrida (ver runbook §8, Paso 3):

- `docker stats --no-stream` muestreado cada 1 s: CPU/memoria por contenedor
  (valida la presión sobre el límite de 512 MiB de la API y 1 GiB de Extraction).
- `docker inspect` final: `OOMKilled`, `RestartCount` y estado de healthcheck
  por contenedor.
- Distribución de status del cliente (200 vs 503 vs timeout) para separar
  backpressure controlado de timeouts no deseados.

### 6.7 Conclusión (a completar con las mediciones)

La hipótesis a validar es que escalar horizontalmente Extraction de 1 a 5
réplicas reduce la latencia y los rechazos por saturación (503) y aumenta el
throughput, según el análisis de la §3. **La conclusión numérica sigue
pendiente:** el pipeline de medición está listo (scripts corregidos, tablas y
runbook en `audit/audit-benchmark.md` §8); solo falta ejecutar las corridas
reales sobre el stack y volcar los valores.

## 7. Entregables y Reproducibilidad

- **Repositorio de código:** los 4 repos con `Dockerfile` y `docker-compose.yml`;
  levantar con `make check && make certs && make up` (equivalente a
  `docker compose up --build` con los contextos de los repos hermanos).
- **Scripts de prueba:** `tests/load/run_k6.sh` (spike k6) y
  `tests/load/vegeta/run_vegeta.sh` (carga fija Vegeta).
- **Informe:** este documento, complementado por la documentación de auditoría
  en `audit/` (`audit-master.md`, `audit-findings.md`, `audit-decisions.md`,
  `audit-benchmark.md`).
