# Audit Master — PDF Extractext

Registro maestro de la auditoría de Arquitectura y Rendimiento de Sistemas Distribuidos.
Carpeta autorizada: `pdf-extractext-infrastructure/audit/` (único lugar válido de documentación de auditoría).

- **Fecha de apertura:** 2026-10-17
- **Workspace:** `Microservicios/`
- **Repositorios auditados:** `pdf-extractext-api`, `pdf-extractext-extractor` (Extraction), `pdf-extractext-persistence`, `pdf-extractext-infrastructure`
- **Modo:** inspección de solo lectura sobre código/configuración; escritura limitada a esta carpeta. **Excepción autorizada (2026-10-17):** implementación acotada de conversión a Markdown (extractor) y alineación D7/D8 (ver §8 y `audit-findings.md`).

---

## 1. Estado de etapas

| Etapa | Nombre | Estado | Notas |
|---|---|---|---|
| Etapa 1 | Relevamiento estructural y línea base | **COMPLETADA (2026-10-17); RE-VERIFICADA (2026-10-18)** | 4/4 repositorios inventariados. `FIND-001`…`FIND-007` definidos; `FIND-005` y `FIND-006` resueltos el 2026-10-17. Re-verificación 2026-10-18: se ajustaron `FIND-001`/`FIND-002`, se agregaron `FIND-008`…`FIND-011` y se alinearon los documentos de infraestructura (§8). |
| Etapa 2 | Auditoría funcional end-to-end e integración | **COMPLETADA (2026-10-18)** | Flujo real trazado y verificado en runtime (§4); matriz `INT-XX` completa; nuevos `FIND-013`…`FIND-015`; `FIND-012` extendido al caso 422. Sin correcciones de código (solo diagnóstico). |
| Etapa 3A | Auditoría del microservicio de extracción (Área B) | **COMPLETADA (2026-10-19); CORRECCIONES APLICADAS (2026-10-19)** | `pdf-extractext-extractor` + interfaz con API inspeccionados en profundidad: algoritmo/Markdown, memoria, concurrencia/workers, errores y backpressure. Nuevos `FIND-016`…`FIND-022`, `RC-010`…`RC-015`, `HYP-07`…`HYP-09`. La auditoría fue solo inspección + sondas locales (ya eliminadas); la fase de correcciones aprobada (Bloque A + B1) resolvió `FIND-016`…`FIND-018`, `FIND-021`, `FIND-022` y parcialmente `FIND-019` (§8, C-27…C-30). |
| Etapa 3B | Auditoría de API, orquestación y persistencia (Área C) | **COMPLETADA (2026-10-19); CORRECCIONES APLICADAS (2026-10-19)** | `pdf-extractext-api` + `pdf-extractext-persistence` inspeccionados: orquestación, cliente HTTP, memoria/BodyLimit, backpressure, Mongo/índices, idempotencia, fallos parciales y Clean Code. Nuevos `FIND-023`…`FIND-031`, `RC-016`…`RC-019`, `ASK-010`…`ASK-013`. La fase de correcciones aprobada resolvió `FIND-023`…`FIND-031` (§8, C-35…C-40). |
| Etapa 3C | Infraestructura (Dockerfile, Twelve-Factor, seguridad de contenedores) y suites de tests | **COMPLETADA (2026-10-19)** | `docker-compose.yml`, Makefile, Traefik, scripts, `.env.example`, los 3 Dockerfiles y las 4 suites inspeccionados + estado runtime del stack. Nuevos `FIND-032`…`FIND-047`, `RC-020`…`RC-029`, `ASK-014`…`ASK-018`. Hallazgo crítico de entorno: `FIND-045` (Traefik del proyecto desconectado; bloquea Etapa 4). Solo se modificaron documentos en `audit/` (§8, C-41…C-44). |
| Etapa 4 | (definida por el equipo) | PENDIENTE | — |
| Etapa 5 | Cierre y reporte final | PENDIENTE | — |

---

## 2. Inventario tecnológico verificado

Etiquetas: toda fila está soportada por lectura directa del manifiesto/archivo indicado.

| Repositorio | Lenguaje / versión | Framework web | Servidor HTTP | Librerías clave | Puntos de entrada | Evidencia |
|---|---|---|---|---|---|---|
| `pdf-extractext-api` | Go 1.27.1 (`go.mod:3`) | Fiber v2 `v2.52.15` | fasthttp `v1.51.0` (vía Fiber) | `google/uuid`, `testify` (dev) | `cmd/api/main.go` (`/extract`, `/upload-pdf`, CRUD `/documents`), `cmd/healthprobe/main.go` | `[VERIFICADO-CÓDIGO]` |
| `pdf-extractext-extractor` (Extraction) | Python `>=3.12` (`pyproject.toml`, `.python-version`, imagen `python:3.12-slim`) | FastAPI `>=0.119.0` | Gunicorn `>=26.2.0` + Uvicorn `uvicorn[standard]>=0.37.0` (`gunicorn.conf.py`) | `pymupdf>=1.28.2` (extracción PDF), `python-multipart`, `pydantic-settings` | `src/pdf_extractext_extractor/main.py` (`create_app`), router `extraction.py` (`POST /extract`), `/health`, `/readyz` | `[VERIFICADO-CÓDIGO]` |
| `pdf-extractext-persistence` | Go 1.27.1 (`go.mod:3`) | chi v5 `v5.3.2` | `net/http` estándar | `go.mongodb.org/mongo-driver/v2 v2.9.1` (driver MongoDB), `google/uuid`, `testcontainers-go/modules/mongodb` (tests, `mongo:8` desde 2026-10-17) | `cmd/api/main.go`, `internal/api/router.go` (`POST/GET/PATCH/DELETE /documents`, `/health`, `/health/ready`, `/readyz`), `cmd/healthprobe/main.go` | `[VERIFICADO-CÓDIGO]` |
| `pdf-extractext-infrastructure` | — (sin app: orquestación) | — | — | Traefik v3 (imagen `traefik:v3`), MongoDB `mongo:8` (parametrizable `MONGO_IMAGE`), Make/Bash/curl/mkcert | `docker-compose.yml` (`name: pdf-extractext`), `Makefile` (`up`, `smoke`, `load-k6`, `load-vegeta`, `record-run`, `certs`, `check`) | `[VERIFICADO-CÓDIGO]` |

Notas adicionales:

- **Clientes HTTP:** API consume Extraction y Persistence con `net/http` encapsulado en `internal/services/extraction_client.go` y `internal/services/persistence_client.go` `[VERIFICADO-CÓDIGO]`.
- **Contrato de respuesta de API:** `POST /extract` devuelve exactamente `{content, page_count}` (`internal/api/extract.go:52-56`) `[VERIFICADO-CÓDIGO]`.
- **Extracción real:** PyMuPDF (`pymupdf.open` + `page.get_text("dict")`) con `page_count` del documento y **conversión a Markdown estructurado** (encabezados, listas, párrafos, separación de páginas) desde 2026-10-17 (`domain/extractor.py`) `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` (§8).
- **Estado de los README vs código:** eran los tres desactualizados respecto del código → `FIND-004`; **actualizados el 2026-10-18** (API, Extraction y Persistence).
- **Modelo de concurrencia de Extraction (Etapa 3A y correcciones posteriores):** Gunicorn con workers Uvicorn (`Dockerfile:37` → `gunicorn.conf.py:5-8`) + `AdmissionMiddleware` con `asyncio.Semaphore` por proceso (`admission.py:33-58`, `MAX_CONCURRENCY`) + extracción delegada a `run_in_threadpool` desde 2026-10-19 (`extraction.py:93-94`). Los defaults de workers se alinearon a 1 (`FIND-021`); Infrastructure ya fijaba 1×1 (`docker-compose.yml:77-79`). `FIND-016` (coste del `get_text("dict")` con imágenes) y `FIND-017` (event loop bloqueado) detallan los dos cuellos de botella medidos y ya corregidos.

---

## 3. Topología en Docker Compose (resumen inicial)

Fuente: `pdf-extractext-infrastructure/docker-compose.yml` `[VERIFICADO-CÓDIGO]`.

```
Host :80/:443 ──► Traefik v3 (:80 redirect → :443 TLS mkcert)
                     │ red `services`
                     ├─► api        :8000 (expuesto solo a red interna; router Host pdf-extractext.localhost)
                     │     ├─► EXTRACTION_URL = http://traefik:8090 (entrypoint interno `internal`)
                     │     └─► PERSISTENCE_URL = http://persistence:8002
                     ├─► extraction :8001 (réplicas: EXTRACTION_REPLICAS 1..5, validado en Makefile `check`)
                     │                 router Host extraction.pdf-extractext.localhost @ entrypoint internal
                     └─► persistence:8002 ──── red `data` ────► mongodb :27017 (NO publicado al host)
```

Límites de recursos por instancia (exigencia del TP) `[VERIFICADO-CÓDIGO]`:

| Servicio | cpus | memoria | Réplicas |
|---|---|---|---|
| traefik | 0.5 | 512M | 1 |
| api | 1.0 | 512M | 1 |
| extraction | 1.0 | 1G | `${EXTRACTION_REPLICAS:-1}` (rango 1–5 forzado en `Makefile:check`) |
| persistence | 1.0 | 512M | 1 |
| mongodb | 1.0 | 1G | 1 |

Aislamiento de redes `[VERIFICADO-CÓDIGO]`:

- `services`: traefik, api, extraction, persistence.
- `data`: mongodb + **únicamente persistence** (único servicio con acceso a la DB).
- Volumen nombrado `pdf-extractext-mongo-data` (sin bind-mount versionado).

Healthchecks declarados: api `/healthprobe`, persistence `/healthprobe`, extraction `urllib /readyz`, mongodb `mongosh ping` `[VERIFICADO-CÓDIGO]`.

---

## 4. Matriz de Contratos (`INT-XX`)

Se llena a partir de la Etapa 2 (contratos inter-servicio verificados en código).

| ID | Emisor | Receptor | Interfaz / endpoint | Contrato verificado | Evidencia | Estado |
|---|---|---|---|---|---|---|
| `INT-01` | API | Extraction | `POST http://traefik:8090/extract` + Host `extraction.pdf-extractext.localhost` (`extraction_client.go:55-64`) | multipart campo `file` (streaming por `io.Pipe`, sin volcar a disco) → `{filename, extracted_text, checksum, content, page_count}` con `extracted_text == content` (Markdown). Timeout cliente 30 s. Errores (corregido, `FIND-012`): los 4xx y el 503 del extractor se propagan tal cual (503 con `Retry-After`); 502 solo para fallos de red/timeout o 500 del upstream; todos en `application/problem+json` (RFC 9457). Límite: BodyLimit API 50 MB < límite defensivo extractor 64 MB (`config.py:14`). | `extraction_client.go`, `extraction.py:113-119`; runtime 2026-10-18 (200/400/415/502) + curas 2026-10-19 (422/503 propagados) | **`[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]`** |
| `INT-02` | API | Persistence | `POST/GET/PATCH/DELETE http://persistence:8002/documents` (`persistence_client.go`) | JSON `{filename, extracted_text, checksum}` → 201/200/204; 404→`ErrNotFound`, 409→`ErrConflict`; ids malformados → 400 validado en la API antes del upstream y 4xx del upstream re-emitidos tal cual (`FIND-013` corregido). Timeout cliente 10 s (30 s en `/upload-pdf` vía ctx). `X-Request-ID` propagado en los 5 métodos (`FIND-014` corregido). Sin reintentos (sin riesgo de duplicar en el cliente). | `persistence_client.go`, runtime 2026-10-18 (404/400→500) + curas 2026-10-19 (400→400, correlación de request-id) | **`[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]`** |
| `INT-03` | Persistence | MongoDB | TCP 27017, red `data` (único servicio con acceso) | driver oficial v2; índice único `checksum_1` creado al arranque con fail-fast (`client.go:71-80` + `cmd/api/main.go`); anti-TOCTOU por `IsDuplicateKeyError` → 409. Sin timeouts ni reintentos explícitos (defaults del driver, serverSelection 30 s). | `client.go`, `document_repository.go:35-51`; `mongosh getIndexes()` runtime 2026-10-18: `checksum_1 unique: true` | **`[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]`** |
| `INT-04` | Traefik | API/Extraction | labels docker; entrypoint `https` :443 (TLS mkcert) para API, entrypoint `internal` :8090 para Extraction | `:8090` no publicado al host; únicos puertos publicados: 80/443 (verificado `docker ps`). Sin `maxRequestBodyBytes` (el límite lo ponen API/Extraction). Sin `responseHeaderTimeout` (default Traefik = sin límite; cap efectivo = 30 s del cliente API). Traefik no tiene healthcheck propio. Etapa 3C: sin middleware `retry` → el 503 de una réplica llega **tal cual** a la API (docs: el retry de Traefik solo aplica si el servidor no responde); exclusión de unhealthy depende del healthcheck Docker (`allowEmptyServices=false`, ventana ≈60 s). **Estado runtime 2026-10-19: degradado**, ver `FIND-045`. | `traefik/traefik.yml`, `docker-compose.yml`, runtime 2026-10-18 + inspección 2026-10-19 | **`[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]`** |

### 4.1 Flujo real verificado (Etapa 2)

- **`POST /extract` (stateless):** Cliente → Traefik :443 (Host `pdf-extractext.localhost`) → API :8000 → `traefik:8090` → Extraction :8001. Runtime 2026-10-18: 200 con `{content, page_count}` exactos (Scrum Guide: `page_count` 16, `content` 35.111 bytes Markdown); 400 sin campo `file` (hoy problem+json, `CON-019` corregido); 415 con no-PDF; 502 con PDF corrupto (422 enmascarado, `FIND-012` — corregido: hoy el 422 se propaga tal cual). Un duplicado siempre responde 200: no hay estado que duplicar.
- **`POST /upload-pdf` (orquestado):** mismo flujo + API → `POST /documents` → Persistence inserta en Mongo confiando en el índice único; duplicado → 409 con el documento existente (verificado en la fase funcional previa 2026-10-18; hoy la colección está vacía, `countDocuments()` = 0).
- **CRUD `/documents`:** la API delega 1:1 en Persistence (validación de id y de longitud de filename en el upstream); id inexistente válido → 404, id malformado → 500 (`FIND-013` — corregido: hoy la API valida hex-24 y responde 400).
- **Aislamiento confirmado en runtime:** redes (`docker network inspect`): `services` = traefik/api/extraction/persistence; `data` = mongodb + persistence; grep negativo confirma que Extraction no llama a ningún servicio y Persistence solo habla con Mongo.
- **Timeouts en cascada:** Traefik sin tope de respuesta → API 30 s (`/extract` vía `http.Client`, `/upload-pdf` vía ctx) + 10 s hacia Persistence → Mongo defaults (30 s serverSelection). El 30 s igual al timeout de Vegeta: sin margen entre capas (referencia para Etapa 3/4).
- **Observaciones de contrato de Extraction (Etapa 3A, corregidas el 2026-10-19 salvo indicación):** (a) un PDF cifrado con contraseña respondía 500 y hoy responde **422 `INVALID_PDF_CONTENT`** (`FIND-018`); (b) la respuesta de `/extract` transporta el Markdown dos veces (`extracted_text` == `content`) aunque la API pública solo `content` (`FIND-020`, decisión D14/INT-01 pendiente de reabrir); (c) el backpressure `503 + Retry-After` ahora cubre también a las solicitudes encoladas: la extracción corre en `run_in_threadpool` y no bloquea el event loop (`FIND-017`), lo que debilita el mecanismo previsto de `HYP-04`/`HYP-09` (pendiente de re-validación en corrida real).

---

## 5. Hipótesis Transversales (`HYP-XX`)

| ID | Hipótesis | Etiqueta | Verificación prevista |
|---|---|---|---|
| `HYP-01` | El cuello de botella del sistema bajo carga es la concurrencia de Extraction (`WEB_CONCURRENCY` × `MAX_CONCURRENCY` por réplica, default 1×1) y no la API. | `[CONFIRMADO EN CÓDIGO - FALTA MEDICIÓN]` (Etapa 3A, parcialmente corregido 2026-10-19): los dos cuellos medidos se corrigieron (`FIND-016` sin decodificar imágenes; `FIND-017` con `run_in_threadpool`), pero la capacidad por réplica sigue acotada a 1×1 (decisión medida). Falta la cifra de rps/p99 con el código actual. | Etapa 3B/4 con benchmarks reales + perfiles de contenedor (`HYP-07`). |
| `HYP-02` | La ausencia de los 4 PDFs oficiales en disco explica que no existan corridas registradas en `docs/test-runs/`. | **`[RESUELTO]`** (2026-10-18): los 4 PDFs están presentes y versionados; hay 5 corridas locales (gitignoreadas) con perfiles aún no corregidos. | `ASK-001` / `ASK-004`. |
| `HYP-03` | El spike de 100 VUs del TP no puede ejecutarse con `make load-k6` tal como está cableado (usa `spike_tests.js` con 1 VU). | **`[CONFIRMADO]`** (2026-10-18) → `FIND-003`. Decisión del equipo: `spike_tests.js` es el canónico (`ASK-003` resuelta) y `k6-spike.js` fue eliminado; las stages 100 VUs se implementan al final del ciclo. | `FIND-003` (abierto). |
| `HYP-04` | Los timeouts de Vegeta (501 de 1.500 en la referencia del TP) se explican por la cola de admisión de Extraction (1 slot/worker) más el timeout cliente de 30s. | `[MECANISMO PARCIALMENTE CORREGIDO - FALTA CORRIDA]` (Etapa 3A, `FIND-017`): con el offload a `run_in_threadpool` (2026-10-19) las peticiones encoladas ya no esperan en serie: el 503 debería alcanzar a todo lo que no consigue slot. Queda la cola del backlog (64) y la capacidad 1×1 por réplica. | Etapa 3B/4 con corrida real. |
| `HYP-05` | El contrato `{content, page_count}` se satisface con texto plano extraído por PyMuPDF; la "conversión a Markdown" del enunciado podría no estar implementada en ningún servicio. | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-17): Markdown nativo implementado en el extractor | `FIND-005` / `ASK-005`: cerrado; ver §8 y `audit-findings.md`. |
| `HYP-06` | La corrida de referencia de Vegeta (1.500 reqs) presupone 50 req/s; el script actual (`RATE="1/s"`) no reproduce ese perfil y explica que no haya corridas comparables registradas. | `[HIPÓTESIS]` | `FIND-007` / `ASK-008` (confirmar rate intencional sin modificar scripts). |
| `HYP-07` | El RSS por réplica de Extraction con el código actual (≥2 copias del binario en RAM + memoria C de MuPDF, sin techo de expansión de páginas) se acerca al límite de **1 GiB** del Compose ante PDFs grandes o altamente comprimidos, pudiendo provocar OOMKill de la réplica (1 worker). | `[HIPÓTESIS]` con soporte en código (`FIND-019`); parcialmente atenuada 2026-10-19: el spool se cierra tras leer, pero siguen abiertos los límites de expansión/páginas/tiempo. | Etapa 3B/4 hacia **Infrastructure**: `docker stats` / `docker inspect` (OOMKilled, restarts) durante cargas con el corpus oficial. **No se probarán PDFs bomba sin autorización explícita.** |
| `HYP-08` | Bajo carga sostenida los healthchecks de Extraction pueden pasar a unhealthy: el probe (`/readyz`, `timeout: 5` en Compose y `3s` en el Dockerfile) se encola detrás de extracciones que bloquean el event loop (retraso medido: 11,6 s en `/health`). | `[HIPÓTESIS]` con mecanismo corregido (`FIND-017` resuelto 2026-10-19 con `run_in_threadpool`; re-medida pendiente). | Etapa 3B/4 hacia **Infrastructure**: estado de salud del contenedor y eventos Docker durante `make load-k6`/`load-vegeta`. |
| `HYP-09` | Bajo saturación, la mayoría de los 502/30 s que ve el cliente proviene de la cola del backlog del socket (64) + serialización por event loop bloqueado, y **no** de respuestas 503: el backpressure actual cubriría solo a las peticiones que llegan con el loop libre. | `[HIPÓTESIS]` con mecanismo parcialmente corregido (`FIND-017` resuelto 2026-10-19; queda el backlog de 64 conexiones). | Etapa 3B/4: distribución de status (503 vs 502/timeout) correlacionada con latencias en corrida real sobre contenedores. |

---

## 6. Lo que funciona correctamente

| # | Aserción | Evidencia | Etiqueta |
|---|---|---|---|
| 1 | Los 4 repositorios existen en el workspace y están completos (manifiestos, Dockerfiles, código fuente, tests). | `find` sobre `Microservicios/` (2026-10-17) | `[VERIFICADO-CÓDIGO]` |
| 2 | Solo Persistence accede a MongoDB: está en la red `data`; Extraction no tiene ninguna referencia a persistence/Mongo (búsqueda sin resultados en `src/`). | `docker-compose.yml:100-120` + grep negativo en `pdf-extractext-extractor/src` | `[VERIFICADO-CÓDIGO]` |
| 3 | `POST /extract` responde HTTP 200 con JSON `{content, page_count}` (contrato TP). | `pdf-extractext-api/internal/api/extract.go:52-56` | `[VERIFICADO-CÓDIGO]` |
| 4 | Acepta PDF binario únicamente como `multipart/form-data` con campo `file` (decisión D14), rechazando no-PDF con 415 y excesos con `BodyLimit`. | `extract.go:21-39`, `main.go:24-29` | `[VERIFICADO-CÓDIGO]` |
| 5 | Límites explícitos de CPU y memoria por instancia en **todos** los servicios del compose. | `docker-compose.yml` (secciones `deploy.resources.limits`) | `[VERIFICADO-CÓDIGO]` |
| 6 | Escalabilidad horizontal de Extraction acotada a 1–5 réplicas con validación en `make check`. | `Makefile:22-25`, `docker-compose.yml:86` | `[VERIFICADO-CÓDIGO]` |
| 7 | Traefik es el único proxy inverso y único entrypoint público; el entrypoint interno `:8090` no se publica al host. | `docker-compose.yml:6-26`, `traefik/traefik.yml` | `[VERIFICADO-CÓDIGO]` |
| 8 | Healthchecks y `depends_on: service_healthy` definidos para arranque ordenado (api espera a extraction+persistence+mongodb). | `docker-compose.yml:45-58, 93-98, 121-126, 145-150` | `[VERIFICADO-CÓDIGO]` |
| 9 | Construcción de imágenes desde repos hermanos parametrizable (`*_CONTEXT`, `*_TAG`) con `check` previo a `make up`. | `.env.example`, `Makefile:19-33` | `[VERIFICADO-CÓDIGO]` |
| 10 | El API orquesta extracción + persistencia (endpoints `/extract` y `/upload-pdf` + CRUD `/documents` registrados en `main.go`). | `pdf-extractext-api/cmd/api/main.go:32-40` | `[VERIFICADO-CÓDIGO]` |
| 11 | El extractor convierte el PDF a Markdown estructurado (encabezados, listas, párrafos, separación de páginas) de forma nativa, sin dependencias nuevas, preservando el contrato `extracted_text == content`. | `pdf-extractext-extractor/src/pdf_extractext_extractor/domain/extractor.py`; `make test` → 76 passed, 1 xfailed | `[VERIFICADO-PRUEBA]` |
| 12 | El contrato público de `POST /extract` devuelve exactamente `{content, page_count}` en runtime (Scrum Guide: `page_count` 16). | `curl` a `https://pdf-extractext.localhost/extract` (2026-10-18) | `[VERIFICADO-PRUEBA]` |
| 13 | Rechazos de cliente correctos: 400 sin campo `file`, 415 con no-PDF, 405 con método no permitido. | `curl` (2026-10-18) | `[VERIFICADO-PRUEBA]` |
| 14 | Índice único `checksum_1` existe efectivamente en Mongo; solo Persistence está en la red `data`; puertos 8000/8001/8002/27017 **no** publicados (únicos expuestos: 80/443). | `mongosh getIndexes()`, `docker network inspect`, `docker ps` (2026-10-18) | `[VERIFICADO-PRUEBA]` |
| 15 | La API orquesta; Extraction no llama a ningún otro servicio (grep negativo de `httpx`/`requests`/`urllib`) y Persistence solo habla con Mongo. | grep sobre `pdf-extractext-extractor/src/` y `pdf-extractext-persistence/internal/` | `[VERIFICADO-CÓDIGO]` |
| 16 | `GET /documents/{id}` inexistente con id válido → 404 `NOT_FOUND`; lista vacía `[]` (nunca `null`). | `curl` (2026-10-18) | `[VERIFICADO-PRUEBA]` |
| 17 | Backpressure real de Extraction: 503 + `Retry-After` directo al upstream bajo saturación (12 `curl` paralelos). | saturación manual (2026-10-18) | `[VERIFICADO-PRUEBA]` |
| 18 | Persistence es fail-fast: sin conexión ni índice único no arranca; escalado de Extraction a 3 réplicas y vuelta a 1 sin downtime. | `cmd/api/main.go` + verificación en vivo (2026-10-18) | `[VERIFICADO-PRUEBA]` |
| 19 | `.env` de Infrastructure no está versionado ni commiteado (gitignoreado). | `git check-ignore .env`, `git ls-files .env` (2026-10-18) | `[VERIFICADO-CÓDIGO]` |
| 20 | Extracción con **una sola apertura** del PDF y `page_count` del mismo objeto: sin doble recorrido ni reabrir el documento para contar páginas (90 = 90 y 16 = 16 verificados por ejecución). | `domain/extractor.py:48-54` + sondas Etapa 3A | `[VERIFICADO-PRUEBA]` |
| 21 | El documento de PyMuPDF se cierra **siempre** con context manager, incluso ante excepciones: sin fugas de recursos nativos del motor. | `domain/extractor.py:48` (`with pymupdf.open(...)`) | `[VERIFICADO-CÓDIGO]` |
| 22 | **Cero archivos temporales en disco**: el multipart se retiene 100 % en memoria (`spool_max_size = math.inf` nunca rueda) → no existen colisiones de nombres bajo solicitudes concurrentes; invariant testeado. | `extraction.py:39-49`; `tests/test_extraction.py:58-70` | `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` |
| 23 | Errores ordinarios controlados, sin 500 escapados ni worker tumbado: vacío → 400, no-PDF/corrupto → 422, multipart malformado/sin `boundary`/campo inexistente → 400, cuerpo sobre el límite → 400 (más el mapeo de los handlers a problem+json). | `extraction.py:85-110`, `errors.py`, suite `tests/api` + `tests/integration` | `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` |
| 24 | Backpressure fail-fast real: 503 + `Retry-After` + code `SERVICE_OVERLOADED` sin espera, y `/health` nunca consume slots; probado en unidad y en proceso (3 solicitudes: 1×200 + 2×503 instantáneos) y en runtime Etapa 2 (12 `curl` paralelos). Desde `FIND-017` (2026-10-19) el 503 también alcanza a las solicitudes encoladas, ya que la extracción corre en `run_in_threadpool`. | `admission.py:42-58`; `tests/api/test_admission.py`, `tests/api/test_concurrency.py` | `[VERIFICADO-PRUEBA]` |
| 25 | Sin estado compartido inseguro entre peticiones: no hay cachés globales, `lru_cache`, hilos ni estructuras mutables compartidas (grep negativo en `src/`); el único contador (`rejections`) pertenece al event loop de su proceso. | grep en `pdf-extractext-extractor/src/` | `[VERIFICADO-CÓDIGO]` |
| 26 | Contrato de los 5 campos estricto y `extracted_text == content` como el mismo string; `page_count` correcto en los 4 PDFs oficiales (90/16/42/62 páginas). | `tests/api/test_extract.py`, `tests/integration/test_api_contract.py` + sondas | `[VERIFICADO-PRUEBA]` |
| 27 | Configuración de concurrencia **correcta en Infrastructure** (1 worker × 1 slot, medida y documentada en ADR 0002) y límites 1 CPU / 1 GiB aplicados a la réplica. | `pdf-extractext-infrastructure/docker-compose.yml:77-90`, `.env.example:18-19` | `[VERIFICADO-CÓDIGO]` |
| 28 | La salida Markdown es **idéntica byte a byte** en los 5 PDFs de prueba aun desactivando la bandera de imágenes: base segura para optimizar `FIND-016` sin romper el contrato (sonda desechable ya eliminada). | sonda local Etapa 3A + `TestImageBlocksAreSkipped` | `[VERIFICADO-PRUEBA]` |
| 29 | El PDF pesado no genera falsos positivos de error: 90 páginas, 121 KiB de Markdown, respuesta 200 con `page_count` coherente; el SHA-256 sobre 8,49 MiB cuesta 0,025 s (despreciable). | sondas Etapa 3A | `[VERIFICADO-PRUEBA]` |
| 30 | **Límites efectivos = declarados** en los 5 contenedores (post-3A/3B): api/persistence/traefik `cpu=1e9 mem=536870912` (traefik `cpu=5e8`), extraction `cpu=1e9 mem=1073741824`, mongodb `cpu=1e9 mem=1073741824`; `no-new-privileges:true` en todos. | `docker inspect` (2026-10-19); `docker compose config` con `EXTRACTION_REPLICAS=3` renderiza `replicas: 3` | `[VERIFICADO-PRUEBA]` |
| 31 | Extracción **escalable 1–5 sin conflictos**: sin `container_name`, sin puertos publicados, sin volúmenes, servicio sin réplica fija; traefik/persistence/mongodb estables. | `docker-compose.yml:76-98`, `Makefile:22-25` | `[VERIFICADO-CÓDIGO]` |
| 32 | Traefik descubre las réplicas por labels (`traefik.enable`, router/`loadbalancer.server.port`), balanceo round-robin por defecto; una réplica unhealthy se excluye del pool (provider docker, `allowEmptyServices=false`). | `docker-compose.yml:78-84` + docs Traefik v3 | `[VERIFICADO-CÓDIGO]` |
| 33 | **Cadena de señales ordenada verificada:** persistence `SIGTERM→graceful` (`NotifyContext`+`Shutdown`) y extraction `SIGTERM→gunicorn graceful 30 s` funcionan por diseño; la API es la excepción (`FIND-033`). | `persistence/cmd/api/main.go:54-77`, `extractor/Dockerfile:37`, `api/cmd/api/main.go:46-49` | `[VERIFICADO-CÓDIGO]` |
| 34 | **Usuarios no-root:** persistence `user=nonroot`, extraction `user=appuser` (uid 10001) verificados en runtime; API corre root (`FIND-032`, excepción). | `docker inspect` (2026-10-19) | `[VERIFICADO-PRUEBA]` |
| 35 | Multi-stage + `.dockerignore` en los 3 servicios: `.git` y `.env` excluidos en los tres; la etapa runtime copia solo binarios/venv (no hay fuga de contexto a la imagen final). | los 3 `Dockerfile` + los 3 `.dockerignore` | `[VERIFICADO-CÓDIGO]` |
| 36 | **Suites verdes (ejecutadas 2026-10-19):** API `go vet` + `go test -race -cover` (89.6 / core 96.3 / services 82.5 %); Persistence `go vet` + `go test -race` + `go vet -tags=integration`; Extractor `make test` → **76 passed, 1 xfailed**; Infrastructure `make check` → OK (sin suite unitaria propia). | ejecución en los 4 repos (2026-10-19) | `[VERIFICADO-PRUEBA]` |
| 37 | Sin variables huérfanas: toda env referenciada en `docker-compose.yml` tiene lector en el servicio correspondiente (cruce compose ↔ `config.go`/`config.py`/gunicorn). | lectura cruzada compose vs configs | `[VERIFICADO-CÓDIGO]` |
| 38 | Build reproducible por parámetros: `*_CONTEXT`/`*_TAG` + `make check` previo a `make up`; `docker compose version` v5.5.1 disponible en el host. | `Makefile:19-33`, salida de `docker compose version` | `[VERIFICADO-PRUEBA]` |
| 39 | Contrato de imágenes de arranque consistente con D3: API binario propio (`ENTRYPOINT exec`), extraction gunicorn (1×1 workers), persistence binario con Mongo fail-fast; healthchecks alineados con los reales (`/health`, `/health` interno, ping Mongo). | los 3 `Dockerfile` + `docker-compose.yml:45-58,93-98,145-150` | `[VERIFICADO-CÓDIGO]` |
| 40 | **Ecuación de capacidad post-3A/3B:** extracción concurrente = réplicas (1–5) × `WEB_CONCURRENCY` 1 × `MAX_CONCURRENCY` 1 → **1–5 peticiones en paralelo**, backlog 64/replica; entrada ≤16 MB (BodyLimit API); techo teórico API ≈16–32 bodies de 16 MB en 512 MiB (`FIND-047`); Traefik 0.5 CPU/512 MiB es SPOF. | `docker-compose.yml:39,44,77,86`, `gunicorn.conf.py`, `.env.example` | `[VERIFICADO-CÓDIGO]` + `[HIPÓTESIS]` (RSS real pendiente) |

---

## 7. Qué no pudo verificarse en la Etapa 1

| Ítem | Motivo | Necesidad |
|---|---|---|
| Cifras de benchmark reales (k6/Vegeta) | Re-verificación 2026-10-18: hay 5 corridas locales en `docs/test-runs/` (gitignoreadas), pero con perfiles aún no corregidos (`FIND-003`/`FIND-007`); no hay corridas válidas versionadas. | Corridas reales en Etapa 3/4 con los perfiles corregidos. |
| Conjunto oficial de PDFs (`tests/stress/pdfs` o `tests/load/pdfs/*.pdf`) | Re-verificación 2026-10-18: los 4 PDFs están presentes en `tests/load/pdfs/` y **se versionan**. `tests/stress/pdfs` sigue sin existir. Uno de los 4 está duplicado (`FIND-011`). | `ASK-002` / `FIND-001`. |
| Comportamiento en runtime (respuestas HTTP, latencias, saturación 503) | **Superado en funcionalidad (Etapa 2, 2026-10-18):** contratos, errores, aislamiento de redes y saturación verificados sobre el stack real. Siguen pendientes las métricas de rendimiento (latencias, percentiles, correlación bajo carga). | Corridas de carga en Etapa 3/4. |
| Contenido de `.env` de Infrastructure | Presente en disco (893 B), gitignoreado y no versionado; credenciales por defecto `dev`/`dev`. No releído por contención con secretos. | Hechos verificados → `ASK-007`; la interpretación es del equipo. |
| Ejecución efectiva de los tests de integración de Persistence | Requieren Docker/testcontainers; en esta sesión solo se verificó su compilación (`go vet -tags=integration`). | Etapa 3 si se habilita Docker. |
| Comportamiento bajo fallo total de un upstream (Mongo/Extraction apagados) | La inducción de caídas requiere detener servicios; no se ejecutó por restricción de la etapa. La traducción de errores está verificada solo en código (503 de Persistence existe en catálogo; el API enmascara igualmente → `FIND-012`). | Etapa 3 (chaos controlado) si el equipo lo habilita. |

### 7.1 Nuevos huecos detectados en la Etapa 3A (auditoría de Extraction)

| Ítem | Motivo | Necesidad |
|---|---|---|
| Specs y carga del host de auditoría (CPU/modelo/carga) | El usuario denegó el acceso a `/proc` (2026-10-19). Los tiempos absolutos de las sondas de la Etapa 3A **no son comparables** con los de Issue #9; solo se reportan ratios intra-máquina (mismo host, misma corrida). | Repetir las mediciones A/B en el entorno de benchmark con specs conocidas. |
| RSS real por réplica en contenedor y memoria C de MuPDF | `tracemalloc` solo traza asignaciones de Python; sin `/proc`, sin `docker stats` y sin levantar el stack en esta etapa. El pico Python medido (20,7 MiB para 8,49 MiB de entrada) **no incluye** el working set de MuPDF. | Etapa 3B/4: `docker stats` / `docker inspect` durante carga (`HYP-07`). |
| Estado de salud del healthcheck de Extraction bajo carga | Requiere stack de contenedores + perfiles de carga (hoy abiertos: `FIND-003`, `FIND-007`). | Etapa 3B/4 (`HYP-08`). |
| Distribución real 503 vs 502/timeout en corrida con contenedores | Las pruebas de concurrencia de la Etapa 3A fueron **in-process** (ASGI), no sobre Traefik/API/contenedores. | Etapa 3B/4 (`HYP-09`). |
| OOM real ante un PDF de expansión agresiva (PDF bomba) | Sería una prueba destructiva: **no intentada** por restricción 6. | Solo con autorización explícita (`HYP-07`). |
| Matriz completa de PDFs cifrados/restringidos | Solo se verificó AES-256 con contraseña de usuario (`FIND-018`); no se probaron RC4, contraseñas vacías ni documentos con permisos de lectura restringidos. | Ampliar la matriz en Etapa 3B si el equipo lo aprueba. |
| Si PyMuPDF libera el GIL durante `get_text("dict")` | Requiere inspección del binding C, no disponible en la etapa. `FIND-017` ya se corrigió con `run_in_threadpool`, pero el paralelismo CPU real depende del GIL. | Necesario para estimar el speedup de concurrencia en la etapa de benchmarks. |

### 7.2 Nuevos huecos detectados en la Etapa 3C (infraestructura, contenedores y suites)

| Ítem | Motivo | Necesidad |
|---|---|---|
| Ejecución del `smoke.sh` sobre el stack escalado | Altera el entorno (restricción 6): el smoke hace 105 `curl` y varias operaciones sobre contenedores vivos. Además, en su estado actual fallaría con `EXTRACTION_REPLICAS>1` (`FIND-039`). | Corregir `FIND-039` y ejecutar el smoke con autorización, en Etapa 4. |
| Escalado a 5 réplicas **en el estado actual** del host | El runtime está degradado (`FIND-045`): el Traefik del proyecto no está en la red `services`; el escalado previamente verificado (2026-10-18, 3 réplicas) no es reproducible hasta restaurar el stack. | Restaurar con autorización (`ASK-017`) antes de la Etapa 4. |
| Métricas de runtime bajo carga (`docker stats`, OOMKilled, RSS por servicio) | Sin ejecución de k6/Vegeta (restricción) y con el entorno degradado. | Etapa 4; valida `HYP-07` y `FIND-047`. |
| Linting con `golangci-lint` en los repos Go | No está instalado en el host; el único CI (`.github/workflows/ci.yml`) existe solo en `pdf-extractext-api` y no corre aquí. | Instalarlo o correr el CI en Etapa 4. |
| Contenido e interpretación de `.env` | No releído por contención con secretos (`ASK-007` sigue abierto). | Interpretación del equipo. |
| Verificación en runtime de DNS `traefik` desde la API | Requeriría `docker exec` en contenedores (restringido). El efecto se deduce de la topología: `pdf-extractext_services` solo contiene api/extraction/persistence (`FIND-045`). | Post-restauración, re-verificar con smoke. |
| Usuario efectivo de MongoDB (`Config.User` vacío) | La imagen oficial deja `Config.User` vacío; el privilegio lo baja el entrypoint (`gosu mongodb`), no verificable sin `exec`. | Baja prioridad; verificar con `docker exec` si el equipo lo habilita. |

---

## 8. Registro de Cambios Implementados (Changelog de Correcciones)

Sesión de implementación acotada del **2026-10-17** (previa a la Etapa 2). Autorizada por el equipo para resolver `FIND-005` y `FIND-006`. No se modificó ningún otro archivo fuera de los listados.

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Verificación | Hallazgo / decisión |
|---|---|---|---|---|---|---|
| C-01 | `pdf-extractext-extractor` | `src/pdf_extractext_extractor/domain/extractor.py` | código | Reescritura con conversión nativa a Markdown (helpers `_page_to_markdown`, `_line_properties`, `_base_font_size`, `_heading_level`, `_bullet_content`); context manager para liberar recursos | `uv run pytest -q` → **70 passed, 1 xfailed** | `FIND-005` / `ASK-005` `[RESUELTO - IMPLEMENTADO]` |
| C-02 | `pdf-extractext-extractor` | `src/pdf_extractext_extractor/extraction.py` | doc | Docstring del contrato aclara que `extracted_text == content` y ese string es Markdown (sin cambio de campos ni lógica) | idem (suite completa verde) | `FIND-005` |
| C-03 | `pdf-extractext-extractor` | `tests/domain/conftest.py` | test | Fixtures `heading_pdf`, `bullet_list_pdf`, `two_paragraphs_pdf` | idem | `FIND-005` |
| C-04 | `pdf-extractext-extractor` | `tests/domain/test_extractor.py` | test | Clase `TestMarkdownConversion` (7 tests) | idem | `FIND-005` |
| C-05 | `pdf-extractext-infrastructure` | `docs/architecture-decisions.md` | doc | **D8** reescrito con el mecanismo real de healthchecks y su justificación; **D7** coordinación marcada como resuelta | revisión estática | `FIND-006` / `DEC-07` / `DEC-08` / `CON-009` |
| C-06 | `pdf-extractext-persistence` | `README.md` | doc | `mongo:7.0` → `mongo:8` (ejemplo local l.35 y nota de tests l.112) | `go build ./...`, `go vet -tags=integration ./...` OK | `FIND-006` / `DEC-07` |
| C-07 | `pdf-extractext-persistence` | `internal/infra/mongo/client_integration_test.go` | — | **Sin cambios:** el código ya usaba `mongo:8` vía `mongoImage()`; se confirmó y documentó | `go test ./...` OK | `FIND-006` |

**Estado de los hallazgos tras la sesión:** `FIND-005` y `FIND-006` → `[RESUELTO - IMPLEMENTADO]`. Siguen abiertos: `FIND-001`, `FIND-002`, `FIND-003`, `FIND-004`, `FIND-007` (documentación de READMEs y scripts de carga, fuera del alcance autorizado de esta sesión).

### Sesión de re-verificación y alineación del 2026-10-18

Contraste de los documentos de `audit/` contra el estado real y corrección de las desviaciones documentales detectadas. Solo documentación (más una robustez menor de script); sin cambios de comportamiento.

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Hallazgo / decisión |
|---|---|---|---|---|---|
| C-08 | `pdf-extractext-infrastructure` | `README.md` | doc | "14 checks" → "15 checks"; PDFs ahora **versionados**; corridas de `docs/test-runs/` locales; nota de perfiles de carga en corrección | `FIND-010` / `CON-015` |
| C-09 | `pdf-extractext-infrastructure` | `.gitignore` | doc | Se elimina la regla `tests/load/pdfs/*.pdf` (los PDFs pasan a versionarse); comentarios reescritos y eliminada la negación muerta `!docs/test-runs/.gitkeep` | `FIND-001` / `FIND-002` / `CON-001` / `CON-002` |
| C-10 | `pdf-extractext-infrastructure` | `docs/architecture-decisions.md` | doc | D9 con la tabla real de límites de los 5 servicios; D5 incluye `API_TAG` | `FIND-009` / `CON-013` |
| C-11 | `pdf-extractext-infrastructure` | `.env.example` | doc | Referencia `docs/pending-decisions.md` → `docs/architecture-decisions.md` | `FIND-009` / `CON-014` |
| C-12 | `pdf-extractext-infrastructure` | `docs/informe_tecnico.md` | doc | §4 neutralizada: se quitaron las cifras "simuladas" y los archivos de corrida inexistentes; queda "pendiente de corridas válidas" | `FIND-008` / `CON-012` |
| C-13 | `pdf-extractext-infrastructure` | `scripts/record-run.sh` | código | `mongo_version()` robustecido (evita emitir "desconocida" espuria) | `FIND-010` |
| C-14 | `pdf-extractext-infrastructure` | `audit/*.md` | doc | Re-verificación de la Etapa 1: `FIND-001`/`FIND-002` ajustados; nuevos `FIND-008`…`FIND-011`, `RC-004`…`RC-006`, `CON-012`…`CON-016`; `ASK-001`/`ASK-004` actualizadas y `ASK-009` agregada | `FIND-011` (PDF oficial duplicado) |
| C-15 | `pdf-extractext-infrastructure` | `.gitignore`, `tests/load/pdfs/*.pdf`, `README.md` | doc/datos | Los 4 PDFs oficiales pasan a **versionarse** (se elimina la regla de exclusión); README actualizado | `FIND-001` / `FIND-002` / `CON-001` / `CON-002` |
| C-16 | `pdf-extractext-api`, `pdf-extractext-extractor`, `pdf-extractext-persistence` | `README.md` (+ `.env.example` de API) | doc | READMEs reescritos/actualizados al estado real (endpoints, contratos, variables, estructura) | `FIND-004` / `CON-003`…`CON-006` |

**Estado de los hallazgos tras la re-verificación (2026-10-18):**
- Resueltos: `FIND-001`, `FIND-002`, `FIND-004`, `FIND-005`, `FIND-006`, `FIND-008`, `FIND-009`, `FIND-010`.
- Abiertos: `FIND-003` (k6 a 1 VU), `FIND-007` (Vegeta a 1 req/s), `FIND-011` (PDF oficial duplicado).
- Pendiente relacionado: ampliar `pdf-extractext-api/docs/openapi.yaml` (hoy solo `/` y `/upload-pdf`).

### Sesión de limpieza pre-commit del 2026-10-18

Consolidación de la suite de carga y clean-code de documentación/comentarios en los 4 repos. Sin cambios de comportamiento del sistema.

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Hallazgo / decisión |
|---|---|---|---|---|---|
| C-17 | `pdf-extractext-infrastructure` | `tests/load/k6-spike.js`, `tests/load/pdfs/generate_fixtures.sh`, `tests/load/test_carga.txt` | script/datos | Eliminados (sin consumidores): suite canónica = `spike_tests.js` + los 4 PDFs oficiales versionados; se retiran también sus referencias en `.gitignore`, README y `audit/` | `FIND-003` / `ASK-003` (resuelta) |
| C-18 | los 4 repos | `README.md`, `docs/`, `Makefile`, `scripts/`, `tests/load/`, `.gitignore`, `.env.example` | doc | Clean-code: comentarios a una línea, sin sobreexplicaciones ni texto redundante | — |
| C-19 | `pdf-extractext-infrastructure` | `audit/audit-findings.md`, `audit/audit-decisions.md`, `audit/audit-master.md` | doc | Registro del nuevo hallazgo `FIND-012` (el 503 + `Retry-After` de Extraction llega al cliente como 502 genérico), con `RC-007` y `CON-017`; corrección **diferida** por decisión del equipo | `FIND-012` / `CON-017` |
| C-20 | `pdf-extractext-infrastructure` | `audit/*.md` | doc | **Etapa 2 completada (solo diagnóstico):** matriz `INT-01`…`INT-04` verificada en código+runtime, flujo real documentado (§4.1), §6 ampliado con verificaciones de runtime, nuevos `FIND-013`…`FIND-015`, `RC-008`/`RC-009`, `CON-018`/`CON-019`; `ASK-007` con hechos verificados | `FIND-013`…`FIND-015` |

### Fase de correcciones del 2026-10-19 (RFC 9457 + FIND-012…015)

Sesión aprobada por el equipo para unificar el contrato de errores de los 3
servicios (RFC 9457, `CON-018`/`CON-019`) y resolver `FIND-012`…`FIND-015`.

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Hallazgo / decisión |
|---|---|---|---|---|---|
| C-21 | `pdf-extractext-extractor` | `src/pdf_extractext_extractor/errors.py`, `admission.py`, `extraction.py`, `README.md`, `tests/*` | código | Errores en `application/problem+json` (RFC 9457): catálogo `PROBLEM_CATALOG` (URN+title por code) y helper `problem_response()`; el 503 de admisión usa el nuevo code `SERVICE_OVERLOADED` en vez de `INTERNAL_ERROR`, conservando `Retry-After`. Tests y README al nuevo contrato. Commit `627aecf`. | `FIND-015` / `CON-018` |
| C-22 | `pdf-extractext-persistence` | `internal/api/errors.go`, `*_test.go`, `tests/contract/*`, `README.md` | código | `problemResponse` RFC 9457 `{type, title, status, detail, code}` con `Content-Type: application/problem+json` y catálogo cerrado `problemCatalog`; el 409 conserva `document` como miembro de extensión (6 campos). Helper de test `assertProblem` y suite de contrato C2 actualizados. Commit `2af0e62`. | `CON-018` |
| C-23 | `pdf-extractext-api` | `internal/api/*.go`, `internal/services/*.go`, `README.md`, `docs/openapi.yaml` | código | **FIND-012:** nuevos `UpstreamError` + `readUpstreamError()` (leen `type`/`title`/`code`/`detail` del problem+json del upstream); los 4xx y el 503 del extractor se propagan tal cual (503 con su `Retry-After`); 502 solo para red/timeout o 500 del upstream. **FIND-013:** id hex-24 validado en GET/PATCH/DELETE `/documents/{id}` (400 sin tocar el upstream) y los 4xx de Persistence se re-emiten tal cual. **FIND-014:** `X-Request-ID` en los 5 métodos del cliente de Persistence. **CON-019:** eliminado el legacy `{"error":"…"}`; `CustomErrorHandler` y todos los handlers responden problem+json. README y OpenAPI (schema `ProblemResponse`, ejemplos, 422/503) actualizados. Tests (incl. E2E de propagación 503/422/500 con upstream real) verdes con `-race`. Commit `fb3d7c3`. | `FIND-012` / `FIND-013` / `FIND-014` / `CON-018` / `CON-019` |
| C-24 | `pdf-extractext-infrastructure` | `docs/architecture-decisions.md`, `scripts/smoke.sh` | doc | **D16** (adopción RFC 9457 en los 3 servicios) y actualización de D10 (503 con `SERVICE_OVERLOADED` propagado); el smoke valida ahora `{"code":"INVALID_REQUEST","status":400,"type":…}` en el 400 de `/extract`. | `CON-018` / `CON-019` / `FIND-012` |

**Estado de los hallazgos (tras la fase de correcciones, 2026-10-19):** abiertos `FIND-003`, `FIND-007`, `FIND-011` (cargas y PDF oficial duplicado); resueltos `FIND-001`/`FIND-002`/`FIND-004`/`FIND-005`/`FIND-006`/`FIND-008`/`FIND-009`/`FIND-010`/`FIND-012`/`FIND-013`/`FIND-014`/`FIND-015` y `CON-017`/`CON-018`/`CON-019`.

**Prioridad declarada por el equipo (2026-10-18):** primero el funcionamiento correcto del sistema. Las pruebas de carga (perfiles de k6 y Vegeta, `FIND-003`/`FIND-007`) y las correcciones abiertas relacionadas con benchmarks (`FIND-011`) quedan para la etapa final.

### Etapa 3A — Auditoría de Extraction (Área B), 2026-10-19

Auditoría profunda de `pdf-extractext-extractor` y de su interfaz directa con `pdf-extractext-api`. **Solo lectura**: no se modificó código, Dockerfiles, Compose, scripts ni datos de prueba.

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Hallazgo / decisión |
|---|---|---|---|---|---|
| C-25 | `pdf-extractext-infrastructure` | `audit/audit-findings.md` | doc | Nuevos `FIND-016`…`FIND-022` (16 campos) y causas raíz `RC-010`…`RC-015` | Etapa 3A |
| C-26 | `pdf-extractext-infrastructure` | `audit/audit-master.md` | doc | Etapa 3A marcada completada; nota de concurrencia en §2; observaciones de contrato en §4.1; `HYP-01`/`HYP-04` actualizados y `HYP-07`…`HYP-09` agregados; §6 con 10 nuevas verificaciones; §7.1 con los huecos nuevos | Etapa 3A |

**Sondas de verificación** (scripts desechables en `/tmp/opencode/`, fuera del repo, ejecutados con el `.venv` del extractor y `PYTHONDONTWRITEBYTECODE=1`; cero cambios fuera de `audit/`: `git status --porcelain` vacío en API, Extractor y Persistence, y en Infrastructure solo los documentos de auditoría):

| Sonda | Qué probó | Resultado |
|---|---|---|
| `audit_3a_probe.py` | PDF cifrado AES-256 → mapeo de error; tiempo/RAM; `/health` concurrente | Cifrado → **500** (`FIND-018`); `/health` retrasado **11,6 s** (`FIND-017`) |
| `audit_3a_mem.py` | Aislamiento de tiempos: apertura vs `get_text()` vs `get_text("dict")` vs SHA-256 | `dict` 6,0-6,7 s vs plano 0,19-0,34 s en `heavy.292.pdf`; SHA-256 0,025 s |
| `audit_3a_time_mem.py` | Desglose de coste por operación (caliente) + pico de memoria de una petición `/extract` con top de ocupadores | `get_text("dict")` domina el tiempo; pico trazado por Python ≈ 19-21 MiB (`FIND-019`) |
| `audit_3a_breakdown.py` | Ratio dict/plain en 2 PDFs | 19,5× (heavy) y 1,6× (Scrum Guide) |
| `audit_3a_flags.py` | Coste por bandera de `get_text("dict")` y composición del PDF | **sin `TEXT_PRESERVE_IMAGES`: 6,67 s → 0,32 s**; 87 imágenes embebidas (`FIND-016`) |
| `audit_3a_flags_equiv.py` | ¿La salida Markdown cambia al quitar la bandera? | **Idéntico byte a byte en los 5 PDFs de prueba** |
| `audit_3a_speedup.py` | Speedup completo del pipeline + identidad de salida | 14,3× / 4,4× / 1,5× / 1,0× según PDF; Markdown idéntico en todos |
| `audit_3a_server_mem.py` | Pico de memoria solo del lado del servidor (tracemalloc) | **20,7 MiB** pico para 8,49 MiB de entrada; 1,25 MiB al final |
| `audit_3a_admission.py` | 3 solicitudes concurrentes: simultáneas vs llegadas con el loop bloqueado | A: `200 + 2×503`; B: `200` en 3,53 s + `200` en 7,46 s (serializada) + `503` (`FIND-017`) |

**Estado de los hallazgos tras la Etapa 3A (2026-10-19):** abiertos `FIND-003`, `FIND-007`, `FIND-011` (cargas y PDF duplicado) **más `FIND-016`…`FIND-022`** (todos de Extraction: 1 cuello de botella de CPU, 1 de concurrencia, 1 contrato de errores, 1 robustez/memoria, 1 optimización sujeta a decisión, 2 de configuración/documentación). Resueltos los anteriores: `FIND-001`/`002`/`004`/`005`/`006`/`008`/`009`/`010`/`012`/`013`/`014`/`015`.

### Fase de correcciones de la Etapa 3A — Bloque A + B1, 2026-10-19

Sesión aprobada por el equipo: resolver `FIND-016`…`FIND-019` (parcial), `FIND-021` y `FIND-022`. Sin benchmarks (solo `make test`), sin commits (todo en working tree) y con `INVALID_PDF_CONTENT` como contrato de `FIND-018` (cero cambios en API/OpenAPI).

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Verificación | Hallazgo |
|---|---|---|---|---|---|---|
| C-27 | `pdf-extractext-extractor` | `src/pdf_extractext_extractor/domain/extractor.py` | código | Flags `TEXTFLAGS_DICT & ~TEXT_PRESERVE_IMAGES` en `get_text("dict")` (sin decodificar imágenes descartadas) y `document.needs_pass` → `InvalidPDFContentError` | `make test` → **76 passed, 1 xfailed**; `TestImageBlocksAreSkipped`, `TestEncryptedPdf` | `FIND-016` / `FIND-018` |
| C-28 | `pdf-extractext-extractor` | `src/pdf_extractext_extractor/extraction.py` | código | `extract_pdf_data` vía `run_in_threadpool` (event loop libre) y `await upload.close()` tras leer el multipart | `tests/api/test_concurrency.py` (2 tests, fallan sin el fix) | `FIND-017` / `FIND-019` (parcial) |
| C-29 | `pdf-extractext-extractor` | `config.py`, `gunicorn.conf.py`, `docker-compose.yml`, `README.md` | config/doc | Eliminado el setting muerto `port` (puerto real 8001) y workers default 4 → 1 (alineado al ADR 0002) | `make test` (verde); `tests/test_container_config.py` sin regresión | `FIND-021` / `FIND-022` |
| C-30 | `pdf-extractext-extractor` | `tests/conftest.py`, `tests/domain/test_extractor.py`, `tests/api/test_extract.py`, `tests/api/test_concurrency.py` | test | Fixture `encrypted_pdf` compartida; tests de PDF cifrado (dominio + API), de concurrencia y de bandera de imágenes; docstrings compactados (Clean Code) en los archivos tocados | `make test` → 76 passed, 1 xfailed | `FIND-017` / `FIND-018` / `FIND-016` |

**Estado de los hallazgos (tras esta sesión, 2026-10-19):**
- Resueltos: `FIND-016`, `FIND-017`, `FIND-018`, `FIND-021`, `FIND-022`.
- Parcial: `FIND-019` (spool liberado; límites de expansión/páginas/tiempo pendientes).
- Abiertos: `FIND-003`, `FIND-007`, `FIND-011` (cargas y PDF duplicado), `FIND-020` (decisión de contrato D14).

### Etapa 3B — Auditoría de API, orquestación y Persistence (Área C), 2026-10-19

Auditoría estática de `pdf-extractext-api` y `pdf-extractext-persistence`. **Solo lectura**: no se modificó código, Dockerfiles, Compose, scripts ni datos.

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Hallazgo / decisión |
|---|---|---|---|---|---|
| C-31 | `pdf-extractext-infrastructure` | `audit/audit-findings.md` | doc | Nuevos `FIND-023`…`FIND-031` (16 campos) y `RC-016`…`RC-019` | Etapa 3B |
| C-32 | `pdf-extractext-infrastructure` | `audit/audit-benchmark.md` | doc | §5: impacto de API/Persistence ante PDFs repetidos, cliente HTTP y Mongo; métricas a medir en la corrida final | Etapa 3B |
| C-33 | `pdf-extractext-infrastructure` | `audit/audit-decisions.md` | doc | `ASK-010`…`ASK-013` (backpressure, RFC 9457 Persistence no reproducible, tamaño, caché de checksum) | Etapa 3B |
| C-34 | `pdf-extractext-infrastructure` | `audit/audit-master.md` | doc | Etapa 3B marcada completada | Etapa 3B |
| C-35 | `pdf-extractext-api` | `internal/services/httpclient.go`, `extraction_client.go`, `persistence_client.go` | code | `Transport` keep-alive explícito compartido (`MaxIdleConnsPerHost=100`, `IdleConnTimeout`) | `FIND-024` |
| C-36 | `pdf-extractext-api` | `cmd/api/main.go`, `pdf-extractext-persistence/cmd/api/main.go` | code | `ReadTimeout`/`WriteTimeout`/`IdleTimeout` en Fiber y `http.Server` | `FIND-025` |
| C-37 | `pdf-extractext-api` | `internal/api/errors.go`, `upload_pdf.go`, `extract.go` (+ tests) | code | `isTimeout` unifica detección de deadline → 504 (`GATEWAY_TIMEOUT`) | `FIND-031` |
| C-38 | `pdf-extractext-api`, `pdf-extractext-infrastructure` | `internal/core/config.go`, `.env.example`, `README.md`, `docker-compose.yml` | code+doc | `MAX_FILE_SIZE_MB` a 16 (umbral de spool de fasthttp); README corregido | `FIND-030`, `ASK-012` |
| C-39 | `pdf-extractext-persistence` | `internal/domain/document.go`, `infra/mongo/document_repository.go`, `api/documents.go` (+ tests) | code | Consolida en `Document`; elimina `PDFDocument`, `repository/`, `pdfdocument_mapper.go`, `existingToResponse` | `FIND-027` |
| C-40 | `pdf-extractext-api`, `pdf-extractext-persistence` | varios `*.go`/`*.md`/`audit/*.md` | code+doc | Clean Code (sin `FIND-XXX`/`Issue #N`), cierre `FIND-023`…`FIND-031`, `ASK-010`…`ASK-013` | `FIND-028`, `ASK-010`…`ASK-013` |

**Verificación ejecutada (solo lectura):** `go build ./...` y `go vet ./...` en ambos repos (verdes); lectura cruzada de `fasthttp@v1.51.0/http.go`, `net/http/transport.go` y `fiber@v2.52.15`. `git log --all` de Persistence **no** contiene `2af0e62` (`FIND-026`).

**Verificación post-corrección (2026-10-19):** `go build ./...`, `go vet ./...`, `go vet -tags=integration ./...` y `go test -race ./...` verdes en `pdf-extractext-api` y `pdf-extractext-persistence`. El `git pull` trajo `2af0e62` (RFC 9457) → `FIND-026`/`FIND-029` resueltos por sincronización.

**Estado de los hallazgos (tras la Etapa 3B, 2026-10-19):** abiertos `FIND-003`, `FIND-007`, `FIND-011` (cargas y PDF duplicado). **`FIND-023`…`FIND-031` resueltos** (implementados o cerrados por decisión de equipo). Resueltos hasta `FIND-022` según el registro anterior.

**Puntos inmediatamente corregibles (bajo decisión del equipo):**
- `FIND-024` / `FIND-025` / `FIND-031`: `Transport` con pool explícito, timeouts de servidor y detección unificada de timeout (bajo riesgo, sin cambio de contrato).
- `FIND-027` / `FIND-028` / `FIND-029`: limpieza de código muerto (`PDFRepository`, mapper legado, tipo `PDFDocument` duplicado), comentarios concisos de 1 línea sin IDs de auditoría, y README de Persistence al estado real.
- `FIND-026` / `ASK-011`: resolver la discrepancia del commit RFC 9457 de Persistence **antes** de dar `CON-018` por resuelta.
- `FIND-023` / `FIND-030` / `ASK-010` / `ASK-012`: decisiones de arquitectura (backpressure y tamaño) que afectan el spike de 100 VUs.

### Etapa 3C — Infraestructura, Dockerfiles, Twelve-Factor, seguridad de contenedores y suites, 2026-10-19

Auditoría estática + inspección de solo lectura del stack. **No se modificó** código, Dockerfiles, compose, scripts ni configuraciones; no se ejecutaron k6/Vegeta ni se reinició/reconectó ningún contenedor.

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Hallazgo / decisión |
|---|---|---|---|---|---|
| C-41 | `pdf-extractext-infrastructure` | `audit/audit-findings.md` | doc | Nuevos `FIND-032`…`FIND-047` (16 campos) y `RC-020`…`RC-029` | Etapa 3C |
| C-42 | `pdf-extractext-infrastructure` | `audit/audit-master.md` | doc | Etapa 3C marcada completada; §4 `INT-04` ampliado; §6 items 30–40; nueva §7.2 | Etapa 3C |
| C-43 | `pdf-extractext-infrastructure` | `audit/audit-decisions.md` | doc | `ASK-014`…`ASK-018`; notas en `DEC-03`, `DEC-09`, `DEC-12` y `R-06` | Etapa 3C |
| C-44 | `pdf-extractext-infrastructure` | `audit/audit-benchmark.md` | doc | §5.5: ecuación de capacidad post-3A/3B y métricas a medir en Etapa 4 | Etapa 3C |

**Verificación ejecutada (solo lectura):**
- Suites: API `go vet ./...` + `go test -race -cover ./...` (verdes, 89.6/96.3/82.5 %); Persistence `go vet ./...`, `go test -race ./...` y `go vet -tags=integration ./...` (verdes); Extractor `make test` → 76 passed, 1 xfailed; Infrastructure `make check` → CHECK_OK.
- Runtime: `docker compose version` v5.5.1; `docker compose config` con `EXTRACTION_REPLICAS=3` (renderiza `replicas: 3` y los límites); `docker inspect` de los 5 contenedores (usuarios, límites, `no-new-privileges`, `StopGracePeriod` ausente = default 10 s); `docker ps`/`docker network inspect`/`docker logs` (solo lectura); `curl -sk https://pdf-extractext.localhost/` → 404.
- Estados git: los 4 repos con working tree limpio (fixes 3A/3B ya commiteados: infra `d96f317`, `b73fd62`, `8c62201`).

**Estado de los hallazgos (tras la Etapa 3C, 2026-10-19):** abiertos `FIND-003`, `FIND-007`, `FIND-011`, `FIND-020` y los nuevos **`FIND-032`…`FIND-047`** (ninguno corregido: la restricción de la etapa lo prohibía). `FIND-045` es **bloqueante para la Etapa 4**.

**Puntos inmediatamente corregibles (bajo decisión del equipo, orden sugerido):**
1. **`FIND-045` (bloqueante):** restaurar el Traefik del proyecto y resolver el conflicto con el Traefik externo en 80/443 — requiere autorización para `docker compose up -d` (`ASK-017`).
2. `FIND-032` / `FIND-033`: usuario nonroot en la API + graceful shutdown (`signal.NotifyContext` + `app.Shutdown`) — bajo riesgo, sin cambio de contrato.
3. `FIND-034`: `stop_grace_period: 35s` en extraction (1 línea en compose).
4. `FIND-039` / `FIND-040`: hacer robusto el smoke para N réplicas y completar OpenAPI (`/extract`, `/documents`, default 16 MB) antes de certificar la Etapa 4.
5. `FIND-038` / `FIND-041` / `FIND-044` / `FIND-043`: alineaciones baratas de config/docs (default Mongo, ejemplos `traefik:8090`, digests, `.dockerignore`).
6. `FIND-036` / `FIND-035` / `FIND-047`: decisiones (`ASK-015`, medición en Etapa 4) — no son parches.

### Fase de correcciones de la Etapa 3C — infraestructura, contenedores y contrato público, 2026-10-20

Sesión aprobada por el equipo (resolución de `ASK-014`…`ASK-018`). Cierra los hallazgos de infraestructura, seguridad de contenedores, documentación OpenAPI y Clean Code. Siete commits, un archivo por commit como máximo; ningún archivo se toca dos veces. Sin benchmarks (diferidos a la Etapa 4: `FIND-046`, `FIND-047` con `FIND-003`/`FIND-007`/`FIND-011`).

| # | Repositorio | Archivo | Tipo | Descripción del cambio | Verificación | Hallazgo / decisión |
|---|---|---|---|---|---|---|
| C-45 | `pdf-extractext-api` | `Dockerfile`, `cmd/api/main.go` | code | Runtime `distroless/static-debian12:nonroot` + `USER nonroot`; arranque con `signal.NotifyContext(SIGINT/SIGTERM)` e `app.ShutdownWithTimeout(10s)`. Commit `4872e6f`. | build OK, `docker inspect` → `user=nonroot`; `go build`/`go vet` verdes | `FIND-032` / `FIND-033` / `ASK-014` |
| C-46 | `pdf-extractext-api` | `docs/openapi.yaml`, `README.md`, `.env.example`, `docker-compose.yml`, `.dockerignore` | doc+config | OpenAPI 1.2.0: `POST /extract` y CRUD `/documents` con componentes reutilizados (`ProblemResponse`, `Document`, `ExtractionResponse`); default 20→16 MB; `EXTRACTION_URL` principal `http://traefik:8090`; compose local con red `pdf-extractext_services` y sin labels muertas; `.dockerignore` ampliado. Commit `ed2dcee`. | YAML válido (17 `$ref` resueltos, 7 `operationId`); `docker compose config` OK | `FIND-040` / `FIND-041` / `FIND-043` / `ASK-016` |
| C-47 | `pdf-extractext-extractor` | `Dockerfile`, `docker-compose.yml`, `Makefile`, `tests/load/profile.sh`, `tests/test_container_config.py` | clean code | Eliminados los IDs `Issue #N`/`FIND-XXX` y las primeras definiciones muertas de `load-test`/`stress-test` (gobernaba la última); `.PHONY` unificado. Commit `d59db50`. | `uv run pytest -q` → 76 passed, 1 xfailed; `make -n` de los 3 targets OK | `FIND-042` |
| C-48 | `pdf-extractext-persistence` | `.dockerignore` | config | Añadidos `tests/`, `Makefile`, `docker-compose.yml` al estándar del extractor. Commit `47e2006`. | `docker build` OK | `FIND-043` |
| C-49 | `pdf-extractext-infrastructure` | `docker-compose.yml`, `traefik/dynamic/config.yml` | config | `stop_grace_period` 35s (extraction) y 15s (api/persistence); healthcheck de Mongo con `${…:-dev}`; dashboard movido al entrypoint `internal` (`:443` exclusivo de la API). Commit `686241d`. | `docker compose config` OK (15s/35s/15s); réplicas propagan | `FIND-034` / `FIND-036` / `FIND-038` / `ASK-015` / `ASK-018` |
| C-50 | `pdf-extractext-infrastructure` | `scripts/smoke.sh`, `tests/load/run_k6.sh` | script | Smokes para 1–5 réplicas (`ps -q` para contar réplicas, `sort -u`, `EXTRACTION_REPLICAS` del entorno manda sobre `.env`); Mongo resuelto por `docker compose ps -q`; check 2 valida dashboard solo en `:8090`; `FIND-003`→"Etapa 4" en el registro de carga. Commit `5f40265`. | `bash -n` OK; smoke 15/15 con 1 y con 3 réplicas | `FIND-039` / `FIND-042` / `ASK-016` |
| C-51 | `pdf-extractext-infrastructure` | `docs/architecture-decisions.md`, `audit/*.md` | doc | D1 (dashboard interno) y D15 (`MAX_FILE_SIZE_MB=16`); nuevas **D17** (`FIND-037` aceptado) y **D18** (`FIND-044` aceptado); cierre de `FIND-032`…`FIND-045`. Commit `I3`. | revisión estática; `git status -s` limpio en los 4 repos | cierre Etapa 3C |

**Verificación ejecutada (runtime, 2026-10-20):**
- `make up` (reconstrucción): las 3 imágenes (`api`, `extraction`, `persistence`) reconstruidas y contenedores recreados; API en runtime `user=nonroot` (uid `65532`).
- `make smoke` → **SMOKE OK** (15/15): check 2 "dashboard interno: 200, público: 404"; check 4 "1 réplica/s".
- `EXTRACTION_REPLICAS=3 make smoke` → **SMOKE OK** (15/15): check 4 "3 réplica/s"; 3 contenedores `extraction-*` healthy.
- Graceful shutdown: `docker stop` de la API → `exit=0`, log `"señal de apagado recibida; drenando conexiones"` + `"servidor detenido correctamente"`.
- Borde público: `https://traefik.pdf-extractext.localhost/api/overview` → **404**; `:8090` interno → **200**; `https://pdf-extractext.localhost/` (API) → **200**.

**Estado de los hallazgos (tras esta fase, 2026-10-20):** resueltos `FIND-032`…`FIND-034`, `FIND-036`, `FIND-038`…`FIND-043`; cerrados por diseño y documentados en el ADR `FIND-035`, `FIND-037`, `FIND-044`; `FIND-045` resuelto (stack restaurado y verificado). Diferidos a la Etapa 4: `FIND-046`, `FIND-047` (con `FIND-003`/`FIND-007`/`FIND-011`).
