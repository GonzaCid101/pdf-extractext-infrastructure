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
| Etapa 2 | Auditoría de arquitectura y contratos | PENDIENTE | Insumo: secciones `INT-XX` de este archivo + `DEC-XX`/`CON-XX` de `audit-decisions.md`. |
| Etapa 3A | (definida por el equipo) | PENDIENTE | — |
| Etapa 3B | (definida por el equipo) | PENDIENTE | — |
| Etapa 3C | (definida por el equipo) | PENDIENTE | — |
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

| ID | Emisor | Receptor | Interfaz / endpoint | Contrato documentado | Evidencia en código | Estado |
|---|---|---|---|---|---|---|
| `INT-01` | API | Extraction | `POST /extract` vía `http://traefik:8090` + Host `extraction.pdf-extractext.localhost` | multipart campo `file` → `{content, page_count}` (D14) | pendiente de Etapa 2 | `[PENDIENTE]` |
| `INT-02` | API | Persistence | `POST/GET/PATCH/DELETE /documents` vía `http://persistence:8002` | por verificar en Etapa 2 | pendiente de Etapa 2 | `[PENDIENTE]` |
| `INT-03` | Persistence | MongoDB | TCP 27017 red `data` | driver oficial v2 + índice único `checksum_1` | pendiente de Etapa 2 | `[PENDIENTE]` |
| `INT-04` | Traefik | API/Extraction | balanceo por labels docker + healthcheck | routers/entrypoints D1/D3 | pendiente de Etapa 2 | `[PENDIENTE]` |

---

## 5. Hipótesis Transversales (`HYP-XX`)

| ID | Hipótesis | Etiqueta | Verificación prevista |
|---|---|---|---|
| `HYP-01` | El cuello de botella del sistema bajo carga es la concurrencia de Extraction (`WEB_CONCURRENCY` × `MAX_CONCURRENCY` por réplica, default 1×1) y no la API. | `[HIPÓTESIS]` | Etapa 3/4 con benchmarks reales + perfiles de contenedor. |
| `HYP-02` | La ausencia de los 4 PDFs oficiales en disco explica que no existan corridas registradas en `docs/test-runs/`. | **`[RESUELTO]`** (2026-10-18): los 4 PDFs están presentes y versionados; hay 5 corridas locales (gitignoreadas) con perfiles aún no corregidos. | `ASK-001` / `ASK-004`. |
| `HYP-03` | El spike de 100 VUs del TP no puede ejecutarse con `make load-k6` tal como está cableado (usa `spike_tests.js` con 1 VU). | **`[CONFIRMADO]`** (2026-10-18) → `FIND-003`. Decisión del equipo: `spike_tests.js` es el canónico (`ASK-003` resuelta) y `k6-spike.js` fue eliminado; las stages 100 VUs se implementan al final del ciclo. | `FIND-003` (abierto). |
| `HYP-04` | Los timeouts de Vegeta (501 de 1.500 en la referencia del TP) se explican por la cola de admisión de Extraction (1 slot/worker) más el timeout cliente de 30s. | `[HIPÓTESIS]` | Etapa 3B/4 con corrida real. |
| `HYP-05` | El contrato `{content, page_count}` se satisface con texto plano extraído por PyMuPDF; la "conversión a Markdown" del enunciado podría no estar implementada en ningún servicio. | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-17): Markdown nativo implementado en el extractor | `FIND-005` / `ASK-005`: cerrado; ver §8 y `audit-findings.md`. |
| `HYP-06` | La corrida de referencia de Vegeta (1.500 reqs) presupone 50 req/s; el script actual (`RATE="1/s"`) no reproduce ese perfil y explica que no haya corridas comparables registradas. | `[HIPÓTESIS]` | `FIND-007` / `ASK-008` (confirmar rate intencional sin modificar scripts). |

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
| 11 | El extractor convierte el PDF a Markdown estructurado (encabezados, listas, párrafos, separación de páginas) de forma nativa, sin dependencias nuevas, preservando el contrato `extracted_text == content`. | `pdf-extractext-extractor/src/pdf_extractext_extractor/domain/extractor.py`; `uv run pytest -q` → 70 passed | `[VERIFICADO-PRUEBA]` |

---

## 7. Qué no pudo verificarse en la Etapa 1

| Ítem | Motivo | Necesidad |
|---|---|---|
| Cifras de benchmark reales (k6/Vegeta) | Re-verificación 2026-10-18: hay 5 corridas locales en `docs/test-runs/` (gitignoreadas), pero con perfiles aún no corregidos (`FIND-003`/`FIND-007`); no hay corridas válidas versionadas. | Corridas reales en Etapa 3/4 con los perfiles corregidos. |
| Conjunto oficial de PDFs (`tests/stress/pdfs` o `tests/load/pdfs/*.pdf`) | Re-verificación 2026-10-18: los 4 PDFs están presentes en `tests/load/pdfs/` y **se versionan**. `tests/stress/pdfs` sigue sin existir. Uno de los 4 está duplicado (`FIND-011`). | `ASK-002` / `FIND-001`. |
| Comportamiento en runtime (respuestas HTTP, latencias, saturación 503) | Parcialmente superado (2026-10-18): verificación funcional manual + `make smoke` (15 checks) sobre el stack real; saturación 503 verificada directo contra Extraction → detectado `FIND-012`. Siguen pendientes las corridas de carga. | Corridas de carga en Etapa 3/4. |
| Contenido de `.env` de Infrastructure | Presente en disco pero no releído por contención con secretos (aunque es un `.env` de desarrollo local, `.gitignore` lo excluye). | `ASK-007` si algún dato de entorno es crítico. |
| Ejecución efectiva de los tests de integración de Persistence | Requieren Docker/testcontainers; en esta sesión solo se verificó su compilación (`go vet -tags=integration`). | Etapa 2/3 si se habilita Docker. |

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

**Estado de los hallazgos tras la limpieza (2026-10-18):** sin cambios de implementación (abiertos `FIND-003`, `FIND-007`, `FIND-011`; `ASK-003` resuelta). Se agrega `FIND-012` (abierto, registrado sin corregir).

**Prioridad declarada por el equipo (2026-10-18):** primero el funcionamiento correcto del sistema. Las pruebas de carga (perfiles de k6 y Vegeta, `FIND-003`/`FIND-007`) y las correcciones abiertas relacionadas con benchmarks (`FIND-011`, `FIND-012`) quedan para la etapa final.
