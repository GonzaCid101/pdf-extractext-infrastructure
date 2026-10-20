# Audit Benchmark — PDF Extractext

Inventario verificado de artefactos de pruebas de carga y referencia externa del TP.
Inspección de solo lectura: `find`, `ls`, `wc`, `sha256sum` (2026-10-17).

---

## 1. Inventario verificado de PDFs de prueba

### 1.1 PDFs presentes en el workspace

| Repo | Ruta | Tamaño (bytes) | SHA-256 | Notas |
|---|---|---|---|---|
| `pdf-extractext-extractor` | `tests/data/heavy.292.pdf` | 8.901.466 | `257f73b908420ac5c78852fb8673beb683a8ca0c05d2e6a82b5e9629f6ad7be8` | Usado por `tests/load/k6_suite.js` y `tests/load/vegeta_target.sh` del repo Extractor. `[VERIFICADO-CÓDIGO]` |

**Total de PDFs en el workspace (2026-10-18): 5** = `heavy.292.pdf` (extractor) + los 4 PDFs oficiales en `tests/load/pdfs/` (ver §1.2). Nota: `Essential-Kanban-Condensed-Spanish.pdf` es una copia exacta de `heavy.292.pdf`. `[VERIFICADO-CÓDIGO]`

### 1.2 PDFs oficiales del TP — presentes y versionados

Re-verificado el 2026-10-18: los 4 PDFs que esperan `run_vegeta.sh:34-43` y `spike_tests.js:17-22` están presentes en `pdf-extractext-infrastructure/tests/load/pdfs/` y **se versionan** en el repo (se eliminó la regla `tests/load/pdfs/*.pdf` de `.gitignore`).

| # | Nombre | Tamaño (bytes) | SHA-256 |
|---|---|---|---|
| 1 | `2020-Scrum-Guide-Spanish-Latin-South-American.pdf` | 319.343 | `6bbff3f361e52016cbb75a72671f1b31b5e043fdc1cc3f022f1b15a32795a256` |
| 2 | `Essential-Kanban-Condensed-Spanish.pdf` | 8.901.466 | `257f73b908420ac5c78852fb8673beb683a8ca0c05d2e6a82b5e9629f6ad7be8` |
| 3 | `Filosofia Lean.pdf` | 668.142 | `c77b55bd68477ecc0d96074ea4606bffe5802a1c8a241a725f6eb358be17ce40` |
| 4 | `scrum_manager_historias_usuario.pdf` | 3.830.899 | `30efd6fcd0c022665676edcf164feb28e6b43dcce53ab9738550b99d70f5fd84` |

- **Hallazgo (`FIND-011`):** el archivo `Essential-Kanban-Condensed-Spanish.pdf` es **byte a byte idéntico** a `pdf-extractext-extractor/tests/data/heavy.292.pdf` (mismo SHA-256 y tamaño). Es decir, el conjunto de 4 PDFs contiene un duplicado de un PDF de 8,9 MB / 292 páginas etiquetado como el documento Kanban, no el documento oficial. Esto afecta la validez del benchmark (rota 4 targets pero dos son el mismo archivo, y uno es desproporcionadamente pesado).
- Ubicación: `pdf-extractext-infrastructure/tests/load/pdfs/` (versionados).
- La ruta del enunciado `tests/stress/pdfs` **no existe** en ningún repo (`FIND-001`, `ASK-002`).

### 1.3 Fixtures generables (eliminados 2026-10-18)

Los fixtures `fixture-1p/3p/8p/20p.pdf` se generaban con
`tests/load/pdfs/generate_fixtures.sh` y los consumía `k6-spike.js:22`. Ambos
archivos **fueron eliminados** (suite canónica = los 4 PDFs oficiales
versionados): `FIND-003` / `ASK-003`.

`[VERIFICADO-CÓDIGO]` — no queda ningún artefacto que los genere ni los consume.

---

## 2. Scripts de benchmark — ubicación verificada

### 2.1 Infrastructure (`pdf-extractext-infrastructure`) — suite del sistema completo

| Herramienta | Ruta | Perfil implementado | Target por defecto | Invocado por |
|---|---|---|---|---|
| k6 (spike 100 VUs) | ~~`tests/load/k6-spike.js`~~ **eliminado 2026-10-18** | 10s→100 VUs, 20s a 100, 10s→0 (40s); rota fixtures `fixture-*.pdf` | — | nunca tuvo invocación (`FIND-003`) |
| k6 (ejecutable) | `tests/load/spike_tests.js` | stages 10s→**1 VU**, 20s a 1, 10s→0; checkea 200 + `{content, page_count}`; rota los 4 PDFs oficiales | `https://pdf-extractext.localhost/extract` | `tests/load/run_k6.sh:21` ← `make load-k6` |
| k6 runner | `tests/load/run_k6.sh` | Exporta resumen, calcula p50/p90/p95/throughput/éxito y registra vía `record-run.sh` (o `RECORD=0`) | — | `Makefile:57-58` |
| Vegeta | `tests/load/vegeta/run_vegeta.sh` | **Documenta** 50 req/s × 30s, timeout 30s, `-insecure`; cuerpos multipart precompilados; rota los 4 PDFs oficiales. **Implementación real: `RATE="1/s"`** (≈30 reqs en 30s, no 1.500) → `FIND-007` | `https://pdf-extractext.localhost/extract` | `Makefile:60-61` (`make load-vegeta`) |
| Mock API (ensayos) | `tests/load/mock_api.py` | Servidor simulado para `RECORD=0` | — | manual |
| Registro de corridas | `scripts/record-run.sh` + `docs/test-runs/TEMPLATE.md` | Genera `docs/test-runs/<fechaUTC>-<tool>.md` con config real del stack | — | `run_k6.sh`, `run_vegeta.sh`, `make record-run` |

`[VERIFICADO-CÓDIGO]` — todos los archivos listados existen y fueron leídos.

### 2.2 Extractor (`pdf-extractext-extractor`) — suite del servicio aislado

| Herramienta | Ruta | Perfil | Target | PDF usado |
|---|---|---|---|---|
| k6 | `tests/load/k6_suite.js` | spike 10s→100, 30s, 5s→0 + carga constante 25 req/s × 60s (startTime 50s); thresholds p99<2s, errores no-503 <1% | `http://localhost:8090/extract` (Host `extraction.pdf-extractext.localhost`) | `tests/data/heavy.292.pdf` (8,5 MB) |
| Vegeta | `tests/load/vegeta_target.sh` | Genera body multipart + target file (el ataque se lanza aparte) | `http://localhost:8090/extract` | `tests/data/heavy.292.pdf` |
| Perfilado | `tests/load/profile.sh` | — | — | — |

`[VERIFICADO-CÓDIGO]`

**Duplicidad:** existen dos suites k6/Vegeta con objetivos distintos (sistema completo vía dominio público vs servicio Extraction aislado). Cuál es la canónica del TP: `ASK-003` / `FIND-003`.

---

## 3. Referencia externa del TP (enunciado de la cátedra) — para contraste

Estas cifras **provienen directamente del enunciado de la cátedra** (información externa a los repos) y no fueron reproducidas en esta auditoría: las 5 corridas de `docs/test-runs/` son locales (gitignoreadas) y usan perfiles aún no corregidos. Se registran como línea base para contrastar en las Etapas 3/4 (`ASK-004`).

Etiqueta: `[DOCUMENTADO-NO-VERIFICADO]`

### 3.1 k6 — Spike

| Métrica | Valor de referencia (TP) |
|---|---|
| Perfil | 0 → 100 VUs en 10s; 20s a 100 VUs; bajada a 0 VUs en 10s (total 40s) |
| Requests totales | 1.037 |
| Throughput | 25,35 req/s |
| Errores | 0% |
| P50 | 1,88 s |
| P90 | 7,83 s |
| P95 | 8,80 s |
| Máximo | 13,94 s |

Coherencia estática observada: ningún script vigente implementa este perfil (`spike_tests.js` usa 1 VU; `k6-spike.js` fue eliminado el 2026-10-18) → `FIND-003`.

### 3.2 Vegeta — Carga abierta

| Métrica | Valor de referencia (TP) |
|---|---|
| Perfil | 50 req/s × 30s (1.500 reqs), rotación de 4 PDFs, timeout cliente 30s |
| Exitosas | 998 |
| Throughput efectivo | 16,65 req/s |
| Timeouts | 501 |
| P50 | 14,89 s |

Coherencia estática observada: `run_vegeta.sh` fija `DURATION=30s`, `TIMEOUT=30s`, `-insecure` y rotación de los 4 PDFs, pero el rate real es `1/s` (no 50 req/s) → `FIND-007`/`CON-011`. La suma de la referencia 998 + 501 = 1.499 ≈ 1.500 reqs es coherente con **50 req/s × 30s**, lo que confirma que la referencia del TP asume 50 req/s y que el script actual (1/s) no la reproduce.

---

## 4. Precondiciones verificadas para ejecutar benchmarks (Estado actual)

| Precondición | Estado | Detalle |
|---|---|---|
| Stack Docker con Traefik + TLS | Por verificar en runtime | Requiere `make certs` (mkcert) y `make up`; certs no generados en este entorno de auditoría |
| `k6`, `vegeta`, `jq` instalados en el host | No verificado | Los scripts hacen `command -v` con fail-fast |
| 4 PDFs oficiales en `tests/load/pdfs/` | **Presentes y versionados** | `FIND-001`; uno de ellos (`Essential-Kanban…`) es un duplicado de `heavy.292.pdf` → `FIND-011` |
| `pdf-extractext.localhost` resuelve a 127.0.0.1 | No verificado | README requiere ajuste manual en WSL/glibc |
| Suite de registro (`record-run.sh`) | Presente | `scripts/record-run.sh`; `docs/test-runs/` con `TEMPLATE.md` versionado + 5 corridas locales (gitignoreadas) |
| Réplicas de Extraction configurables 1–5 | Verificado (código) | `Makefile:check` valida el rango antes de `make up` |

---

## 5. Impacto esperado de API/Persistence en las corridas finales (Etapa 3B, 2026-10-19)

Análisis estático; **sin ejecutar cargas** (restricción 6). Puntos a contrastar en la corrida real.

### 5.1 PDF repetido (`POST /extract` vs `POST /upload-pdf`)

- **`/extract` (stateless):** no consulta Persistence. El mismo PDF siempre dispara `Extraction` de nuevo y responde 200. Con los 4 PDFs rotados por k6/Vegeta, el costo CPU se paga completo en cada request.
- **`/upload-pdf` (orquestado):** **no hay caché/consulta previa por checksum**. Flujo real: `Extraction` (siempre) → `Persistence.Create` → `InsertOne` a ciegas → el índice único `checksum_1` dispara `IsDuplicateKeyError` → recupera el existente → 409 con el documento. Es decir, el caso (a) "efecto caché" **no existe**; aplica (b): siempre se extrae y luego 409. Bajo carga repetida el trabajo de extracción se duplica y solo se evita la segunda escritura.
- **Idempotencia / concurrencia:** el `Save` es `insert` (no `upsert`). No hay `race` que duplique documentos (el índice `unique` lo impide y el perdedor cae en 409), pero sí hay *retrabajo*: N clientes simultáneos con el mismo PDF ejecutan N extracciones y N-1 inserts fallidos.
- **Implicación para el benchmark:** los PDFs rotados son 4 contenidos (uno de ellos `FIND-011` es duplicado de `heavy.292.pdf`), así que dentro de una corrida de Vegeta de 1.500 reqs el mismo checksum aparece muchas veces → se esperan muchos **409**, no 201. Los percentiles de `/upload-pdf` medirán extracción + escritura fallida, no caché.

### 5.2 Cliente HTTP y concurrencia de la API

> **Post-corrección (2026-10-19):** `FIND-024`, `FIND-025` y `FIND-030` fueron resueltos antes de la corrida; se anotan abajo los valores vigentes.

- `MaxIdleConnsPerHost=100` con `IdleConnTimeout` explícito (resuelto, `FIND-024`): sin churn de conexiones esperado al sostener keep-alive con 100 VUs sobre 1 host.
- Sin rate limiting ni semáforo (decisión del equipo, `ASK-010`): los 100 VUs llegan enteros a Traefik/Extraction; el rechazo efectivo lo produce el 503 de Extraction, no el borde.
- **`MAX_FILE_SIZE_MB=16`** (resuelto, `FIND-030`): cubre el PDF pesado (8,9 MB) y se fija bajo el umbral de spool de fasthttp; la memoria de la API (límite 512 MiB) sigue siendo el recurso a vigilar con `docker stats`.

### 5.3 Persistencia / Mongo

- Cliente Mongo único y reutilizado (`mongo.Connect` una vez, pool del driver por defecto): correcto, sin conexión por request.
- Timeouts explícitos en `http.Server` (resuelto, `FIND-025`) y timeout de red mapeado a 504 `GATEWAY_TIMEOUT` (resuelto, `FIND-031`): un Mongo degradado no se reporta como 502 genérico.
- La recuperación del documento existente en el 409 (`FindOne` extra) ocurre solo en el camino de conflicto: con checksums repetidos añade una lectura por cada 409.

### 5.4 Qué medir en la corrida final

| Punto | Métrica / salida esperada |
|---|---|
| `/upload-pdf` con PDF repetido | Proporción 201 vs 409 y p95/p99 (retrabajo de extracción) |
| Cliente API bajo 100 VUs | `docker stats` de api (RSS vs 512 MiB), `TIME_WAIT`, latencia p99 |
| Backpressure | Distribución 503 (borde/servicio) vs 502/timeout (`HYP-04`, `HYP-09`) |
| Persistencia | Latencia de `POST /documents` y de la `FindOne` de conflicto |

### 5.5 Ecuación de capacidad post-3A/3B (Etapa 3C, 2026-10-19)

| Capa | Cota real | Evidencia |
|---|---|---|
| Extracción concurrente | réplicas (1–5) × `WEB_CONCURRENCY=1` × `MAX_CONCURRENCY=1` = **1–5 peticiones simultáneas**; backlog 64/replica | `docker-compose.yml:77,86`, `.env.example:18-19` |
| Entrada por request | ≤ 16 MB (`MAX_FILE_SIZE_MB`, `BodyLimit` de fasthttp) | `docker-compose.yml:39`, `cmd/api/main.go:25` |
| Memoria API | 512 MiB con body bufferizado en RAM → techo teórico ≈16–32 bodies concurrentes de 16 MB; sin límite de concurrencia en la API → único control de admisión: 503 de Extraction | `FIND-047`, `FIND-023`/`ASK-010` |
| Memoria Extraction | 1 GiB/réplica; pico Python medido 20,7 MiB (entrada 8,49 MiB) **sin** incluir MuPDF (pendiente `HYP-07`) | Etapa 3A, `docker inspect` |
| Persistencia / Mongo | 512 MiB (timeouts 10/15/120 s) / 1 GiB | `docker-compose.yml`, `FIND-025` |
| Borde | Traefik 0.5 CPU / 512 MiB, **1 instancia (SPOF)**, sin tope propio de tiempo de respuesta (cap = 30 s del cliente API) | `FIND-035`, `INT-04` |

**A confirmar en Etapa 4:** RSS real por servicio, OOMKilled de API bajo spike 100 VUs (`FIND-047`) y distribución 503 vs 502/timeout con el stack restaurado (`FIND-045`).

---

## 6. Restricciones aplicadas en la generación de este documento

- No se ejecutaron benchmarks, servicios ni cargas (restricción 6 del enunciado de auditoría).
- No se modificaron scripts, Dockerfiles, compose ni datos de prueba.
- Hashes calculados con `sha256sum` sobre el único PDF presente; tamaños con `ls -la`/`wc -c`.
- §5 es análisis estático del código (fasthttp, clientes HTTP, driver Mongo); no son mediciones.
- §5.5 (Etapa 3C) cruza compose/configs con las suites ejecutadas; la RSS/estabilidad real queda pendiente de Etapa 4 (`FIND-045`, `FIND-047`).
