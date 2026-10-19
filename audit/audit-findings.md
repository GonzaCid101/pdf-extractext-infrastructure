# Audit Findings — PDF Extractext

Registro de hallazgos. Plantilla de 16 campos:
`ID`, `Título`, `Etapa`, `Categoría`, `Severidad`, `Repositorio`, `Ubicación`,
`Descripción`, `Evidencia`, `Taxonomía`, `Impacto`, `Descubrimiento`,
`Causa raíz`, `Acción recomendada`, `Estado`, `Restricciones`.
Taxonomía: `[VERIFICADO-CÓDIGO]`, `[VERIFICADO-PRUEBA]`, `[DOCUMENTADO-NO-VERIFICADO]`, `[HIPÓTESIS]`, `[RECOMENDACIÓN]`, `[DECISIÓN-PENDIENTE]`.

---

## Causas Raíz (`RC-XX`)

| ID | Causa raíz | Hallazgos | Estado | Etiqueta |
|---|---|---|---|---|
| `RC-001` | Los PDFs oficiales nunca se versionaron (`.gitignore` desalineado con el README). | `FIND-001`, `FIND-002` | Resuelta (2026-10-18) | `[VERIFICADO-CÓDIGO]` |
| `RC-002` | READMEs y ADRs no se actualizaron tras la implementación posterior al bootstrap. | `FIND-004`, `FIND-006` | Resuelta (2026-10-17/18) | `[VERIFICADO-CÓDIGO]` |
| `RC-003` | Dos suites de carga sin script canónico definido. | `FIND-003`, `FIND-007` | Abierta (perfiles al final del ciclo) | `[VERIFICADO-CÓDIGO]` |
| `RC-004` | El informe técnico se redactó con datos simulados y no se reemplazaron. | `FIND-008` | Resuelta (2026-10-18) | `[VERIFICADO-CÓDIGO]` |
| `RC-005` | ADR/README/`.env.example` evolucionaron sin revisión cruzada. | `FIND-009`, `FIND-010` | Resuelta (2026-10-18) | `[VERIFICADO-CÓDIGO]` |
| `RC-006` | El corpus de carga se armó sin verificar procedencia/hash (duplicado del PDF pesado). | `FIND-011` | Abierta | `[VERIFICADO-CÓDIGO]` |
| `RC-007` | El cliente HTTP del API colapsaba cualquier status de upstream en error genérico. | `FIND-012`, `FIND-013` | Resuelta (API `fb3d7c3`) | `[VERIFICADO-PRUEBA]` |
| `RC-008` | `persistence_client.go` no enviaba `X-Request-ID`. | `FIND-014` | Resuelta (API `fb3d7c3`) | `[VERIFICADO-PRUEBA]` |
| `RC-009` | El 503 de saturación reutilizaba el code `INTERNAL_ERROR`. | `FIND-015` | Resuelta (extractor `627aecf`) | `[VERIFICADO-PRUEBA]` |
| `RC-010` | La reescritura a Markdown (`3d9df00`, 2026-10-17) cambió el coste del hot path sin re-medir ni revalidar Issue #9 / ADR 0002 (2026-10-07). | `FIND-016`, `FIND-021` | Resuelta (2026-10-19) | `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` |
| `RC-011` | La extracción CPU-bound se ejecuta como código síncrono dentro del endpoint `async def` (un solo event loop). | `FIND-017` | Resuelta (2026-10-19) | `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` |
| `RC-012` | El mapeo de errores de PyMuPDF solo cubre `FileDataError`/`EmptyFileError`; el resto cae en el `except Exception` genérico. | `FIND-018` | Resuelta (2026-10-19) | `[VERIFICADO-PRUEBA]` |
| `RC-013` | El límite defensivo acota solo el tamaño de entrada: sin límite de expansión, páginas ni tiempo. | `FIND-019` | Parcial (2026-10-19): spool liberado; límites pendientes | `[VERIFICADO-CÓDIGO]` |
| `RC-014` | El contrato exige `extracted_text == content`: el Markdown viaja dos veces. | `FIND-020` | Abierta (decisión de contrato) | `[VERIFICADO-PRUEBA]` |
| `RC-015` | Los defaults de arranque del extractor nunca se alinearon con la decisión medida del ADR 0002 (1 worker). | `FIND-021` | Resuelta (2026-10-19) | `[VERIFICADO-CÓDIGO]` |

---

## Hallazgos

### FIND-001

| Campo | Valor |
|---|---|
| **ID** | `FIND-001` |
| **Título** | Los 4 PDFs oficiales no estaban versionados (excluidos por `.gitignore`) |
| **Etapa** | Etapa 1 (resuelto 2026-10-18) |
| **Categoría** | testing / configuración |
| **Severidad** | Alta (impedía reproducir la línea base desde un clon limpio) |
| **Repositorio** | Workspace (los 4 repos) |
| **Ubicación** | `pdf-extractext-infrastructure/tests/load/pdfs/`; regla `tests/load/pdfs/*.pdf` de `.gitignore` (eliminada). `tests/stress/pdfs` del enunciado no existe en ningún repo. |
| **Descripción** | Los 4 PDFs oficiales estaban en disco pero excluidos por `.gitignore`. Decisión del equipo: versionarlos. |
| **Evidencia** | Antes: `git ls-files tests/load/pdfs` → solo `generate_fixtures.sh`. Ahora: regla eliminada y 4 `.pdf` en el índice. `find -type d -name stress` → sin resultados. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Resuelto: un clon limpio contiene el corpus de carga. |
| **Descubrimiento** | Re-verificación de filesystem y `git ls-files` (2026-10-18). |
| **Causa raíz** | `RC-001` |
| **Acción** | Hecho. Pendiente calidad del dato (`FIND-011`) y confirmar `tests/stress/pdfs` (`ASK-002`). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-18) |
| **Restricciones** | No se sustituyen por fixtures artificiales. |

### FIND-002

| Campo | Valor |
|---|---|
| **ID** | `FIND-002` |
| **Título** | `.gitignore` y README se contradecían sobre el versionado de los PDFs |
| **Etapa** | Etapa 1 (resuelto 2026-10-18) |
| **Categoría** | documentación / configuración |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `.gitignore` (regla eliminada) y `README.md` (§Pruebas de carga) |
| **Descripción** | El comentario del `.gitignore` decía que los PDFs ya estaban copiados mientras la línea siguiente los ignoraba; el README daba a entender lo mismo. Corregido: regla eliminada y README declara que **sí** se versionan; `docs/test-runs/` sigue siendo local. |
| **Evidencia** | Antes: `.gitignore` + `README.md` §Pruebas de carga. Ahora: sin regla; README "PDFs oficiales … SÍ se versionan". |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo tras la corrección. |
| **Descubrimiento** | Contraste entre documentación y trackeo real. |
| **Causa raíz** | `RC-001` |
| **Acción** | Hecho por decisión del equipo (2026-10-18). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-18) |
| **Restricciones** | También `CON-001`/`CON-002` en `audit-decisions.md`. |

### FIND-003

| Campo | Valor |
|---|---|
| **ID** | `FIND-003` |
| **Título** | `make load-k6` ejecuta un spike de 1 VU, no el de 100 VUs del TP |
| **Etapa** | Etapa 1 |
| **Categoría** | rendimiento / configuración |
| **Severidad** | Alta |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `Makefile:57-58` → `tests/load/run_k6.sh:21` → `tests/load/spike_tests.js:8-12` (stages `target: 1`); `k6-spike.js` (100 VUs) eliminado el 2026-10-18. |
| **Descripción** | El README describe "spike 10s→100 VUs" pero `spike_tests.js` sube a 1 VU. Decisión del equipo: `spike_tests.js` es el canónico; las stages de 100 VUs se implementan al final del ciclo. |
| **Evidencia** | `run_k6.sh:21` ejecuta `spike_tests.js`; `spike_tests.js:9-11`: `target: 1`; `k6-spike.js` no referenciado (eliminado). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | El benchmark cableado no reproduce el escenario del TP (100 VUs). |
| **Descubrimiento** | Lectura cruzada Makefile → scripts k6 vs enunciado. |
| **Causa raíz** | `RC-003` |
| **Acción** | Implementar stages 100 VUs en `spike_tests.js` al corregir perfiles (`ASK-003` resuelta). |
| **Estado** | Abierto (perfil pendiente) |
| **Restricciones** | Corrección pospuesta a la etapa final de benchmarks. |

### FIND-004

| Campo | Valor |
|---|---|
| **ID** | `FIND-004` |
| **Título** | READMEs de API, Extraction y Persistence desactualizados frente al código |
| **Etapa** | Etapa 1 (resuelto 2026-10-18) |
| **Categoría** | documentación |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api`, `pdf-extractext-extractor`, `pdf-extractext-persistence` |
| **Ubicación** | Los 3 README + comentario de `pdf-extractext-api/.env.example` |
| **Descripción** | Describían un estado "bootstrap" superado: API negaba `/extract`, CRUD y consumo de `PERSISTENCE_URL`; Extraction declaraba respuesta `{filename, size}`; Persistence decía CRUD "por implementar". Reescritos al estado real. |
| **Evidencia** | API registra los 3 grupos de rutas (`cmd/api/main.go:36-40`) y consume `PERSISTENCE_URL`; Extraction devuelve los 5 campos y expone probes; Persistence registra CRUD + probes (`router.go:26-37`). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo tras la corrección. |
| **Descubrimiento** | READMEs vs `main.go`/`router.go`/`extraction.py`. |
| **Causa raíz** | `RC-002` |
| **Acción** | Hecho. Pendiente ampliar `pdf-extractext-api/docs/openapi.yaml`. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-18) |
| **Restricciones** | Solo documentación. |

### FIND-005

| Campo | Valor |
|---|---|
| **ID** | `FIND-005` |
| **Título** | No existía conversión a Markdown: `content` era texto plano de PyMuPDF |
| **Etapa** | Etapa 1 |
| **Categoría** | contrato |
| **Severidad** | Media (brecha funcional vs enunciado) |
| **Repositorio** | `pdf-extractext-extractor` (+ `pdf-extractext-api`) |
| **Ubicación** | `domain/extractor.py` (reescrito), `internal/api/extract.go:52-56` |
| **Descripción** | El enunciado pide Markdown; se concatenaba `page.get_text()` plano. Decisión: convertir a Markdown nativo con PyMuPDF (sin ML/OCR): encabezados por tamaño/negrita, viñetas, párrafos y separador de página `\n\n---\n\n`. Contrato de campos intacto (`extracted_text == content`). |
| **Evidencia** | Implementación 2026-10-17 (`3d9df00`): `_page_to_markdown`, `_line_properties`, `_base_font_size`, `_heading_level`, `_bullet_content` en `domain/extractor.py`; 7 tests `TestMarkdownConversion` en `tests/domain/test_extractor.py`; suite `70 passed, 1 xfailed`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` |
| **Impacto** | Brecha cerrada. |
| **Descubrimiento** | Lectura del dominio durante el inventario tecnológico. |
| **Causa raíz** | Sin asignar |
| **Acción** | Hecho (`ASK-005`). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-17) |
| **Restricciones** | Solo PyMuPDF nativo. |

### FIND-006

| Campo | Valor |
|---|---|
| **ID** | `FIND-006` |
| **Título** | Deriva entre ADRs de Infrastructure y la implementación (healthchecks D8, Mongo D7) |
| **Etapa** | Etapa 1 (resuelto 2026-10-17) |
| **Categoría** | documentación / configuración |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure`, `pdf-extractext-persistence` |
| **Ubicación** | `docs/architecture-decisions.md` (D7, D8), `docker-compose.yml`, `persistence/README.md` |
| **Descripción** | D8 describía healthchecks `CMD-SHELL`+`curl` cuando se usa `/healthprobe` (distroless) y `python3 urllib` en Extraction; D7 asumía coordinación pendiente de Mongo y el README citaba `mongo:7.0` cuando el código ya usaba `mongo:8` (`mongoImage()`). Corregido: D8 reescrito con el mecanismo real, D7 cerrado y README alineado. |
| **Evidencia** | `docker-compose.yml:45-48,93-98,121-126`; D8 (`architecture-decisions.md:53-72`); `internal/infra/mongo/client_integration_test.go:27-32`. Tests de integración no ejecutados: verificado `go vet -tags=integration ./...`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` + `[DOCUMENTADO-NO-VERIFICADO]` |
| **Impacto** | Bajo. |
| **Descubrimiento** | ADR vs compose vs README. |
| **Causa raíz** | `RC-002` (parcial) |
| **Acción** | Hecho (`ASK-006`). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-17) |
| **Restricciones** | Se conserva la implementación real de healthchecks. |

### FIND-007

| Campo | Valor |
|---|---|
| **ID** | `FIND-007` |
| **Título** | `run_vegeta.sh` ataca a 1 req/s en vez de los 50 req/s documentados |
| **Etapa** | Etapa 1 |
| **Categoría** | rendimiento / configuración |
| **Severidad** | Alta (30 reqs en 30 s vs 1.500 esperados) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/vegeta/run_vegeta.sh:21` (`RATE="1/s"`) vs `:71` (`-rate="$RATE"`); README `:76`; D11 `:71` |
| **Descripción** | `RATE` está hardcoded a `1/s` (sin default sobreescribible), mientras script, README y ADR documentan 50 req/s. Decisión del equipo: corregir el rate a `50/s` en la etapa final. |
| **Evidencia** | `run_vegeta.sh:21` `RATE="1/s"`; `:71-72` lo pasa a `vegeta attack`; README/D11 documentan 50 req/s. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Corridas no comparables con la referencia del TP (1.500 reqs, 501 timeouts). |
| **Descubrimiento** | Contraste comentario/README/ADR vs valor de `RATE`. |
| **Causa raíz** | `RC-003` |
| **Acción** | Corregir a `50/s` en la etapa final de benchmarks. |
| **Estado** | Abierto (corrección diferida) |
| **Restricciones** | Prioridad: funcionamiento correcto primero. |

### FIND-008

| Campo | Valor |
|---|---|
| **ID** | `FIND-008` |
| **Título** | `docs/informe_tecnico.md` presentaba métricas marcadas como "simulado" |
| **Etapa** | Re-verificación 2026-10-18 |
| **Categoría** | documentación / rendimiento |
| **Severidad** | Alta (documento entregable con resultados no medidos) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `docs/informe_tecnico.md:47-84` |
| **Descripción** | Comparativa 1 vs 5 réplicas (p95, throughput, 503/500%) con "fuentes" rotuladas "simulado" y archivos de corrida inexistentes. Reemplazada por sección "pendiente de corridas válidas". |
| **Evidencia** | Texto decía "Archivo de Registro (simulado)"; `docs/test-runs/` no contiene los archivos citados. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Riesgo alto antes de corregir. |
| **Descubrimiento** | Revisión de huecos de la Etapa 1. |
| **Causa raíz** | `RC-004` |
| **Acción** | Hecho (2026-10-18). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-18) |
| **Restricciones** | No se inventaron métricas de reemplazo. |

### FIND-009

| Campo | Valor |
|---|---|
| **ID** | `FIND-009` |
| **Título** | Deriva del ADR (D9 límites, D5 `API_TAG`) y referencia muerta en `.env.example` |
| **Etapa** | Re-verificación 2026-10-18 |
| **Categoría** | documentación / configuración |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `docs/architecture-decisions.md` (D5, D9); `.env.example:3` |
| **Descripción** | D9 decía "sin límites en desarrollo" pero el compose limita los 5 servicios; D5 omitía `API_TAG`; `.env.example` citaba `docs/pending-decisions.md` (eliminado). Corregido. |
| **Evidencia** | `docker-compose.yml` con `deploy.resources.limits` en los 5 servicios; D5/D9; `.env.example:3`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo. |
| **Descubrimiento** | ADR ↔ compose ↔ `.env.example`. |
| **Causa raíz** | `RC-005` |
| **Acción** | Hecho (2026-10-18). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-18) |
| **Restricciones** | — |

### FIND-010

| Campo | Valor |
|---|---|
| **ID** | `FIND-010` |
| **Título** | README de Infrastructure desalineado (conteo de checks, artefactos locales) y `record-run.sh` con versión de Mongo espuria |
| **Etapa** | Re-verificación 2026-10-18 |
| **Categoría** | documentación / testing |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `README.md:42`, §Pruebas de carga; `scripts/record-run.sh` (`mongo_version`) |
| **Descripción** | README decía "14 checks" (hay 15) y no aclaraba que PDFs y `docs/test-runs/` son locales; `mongo_version()` podía emitir versión y "desconocida" a la vez. Corregido y robustecido. |
| **Evidencia** | `scripts/smoke.sh` (checks 1–15); registros locales con "desconocida". |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo. |
| **Descubrimiento** | README ↔ smoke.sh y lectura de registros locales. |
| **Causa raíz** | `RC-005` |
| **Acción** | Hecho (2026-10-18). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-18) |
| **Restricciones** | Los registros ya generados no se reescriben. |

### FIND-011

| Campo | Valor |
|---|---|
| **ID** | `FIND-011` |
| **Título** | `Essential-Kanban-Condensed-Spanish.pdf` es copia exacta de `heavy.292.pdf` |
| **Etapa** | Re-verificación 2026-10-18 |
| **Categoría** | testing / rendimiento |
| **Severidad** | Alta (invalida la rotación de 4 documentos distintos) |
| **Repositorio** | `pdf-extractext-infrastructure` (datos) |
| **Ubicación** | `tests/load/pdfs/Essential-Kanban-Condensed-Spanish.pdf` vs `pdf-extractext-extractor/tests/data/heavy.292.pdf` |
| **Descripción** | Byte a byte idénticos: 8.901.466 bytes y SHA-256 `257f73b9…ad7be8` en ambos. El corpus no tiene 4 documentos distintos. |
| **Evidencia** | `sha256sum` igual; `cmp -s` sin diferencias; mismo tamaño. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Dos de los 4 targets de Vegeta apuntan al mismo contenido pesado; comparación con la referencia del TP inválida. |
| **Descubrimiento** | Hashes de los 4 PDFs durante la re-verificación. |
| **Causa raíz** | `RC-006` |
| **Acción** | Reemplazar por el documento oficial real y verificar hashes (`ASK-009`). |
| **Estado** | Abierto |
| **Restricciones** | No se modificaron datos de prueba. |

### FIND-012

| Campo | Valor |
|---|---|
| **ID** | `FIND-012` |
| **Título** | El 503 + `Retry-After` de Extraction llegaba al cliente como 502 genérico |
| **Etapa** | Verificación funcional 2026-10-18 |
| **Categoría** | contrato / configuración |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api` (+ Extraction) |
| **Ubicación** | `internal/services/extraction_client.go:72-73`; `internal/api/extract.go:47`; `internal/api/upload_pdf.go:65,73` |
| **Descripción** | El cliente del API descartaba status y header del upstream y los handlers respondían 502: el cliente final nunca veía el backpressure controlado. También afectaba a los 422. |
| **Evidencia** | Directo a Extraction (12 `curl`): 503 + `Retry-After`. Vía Traefik (14 `curl`): 3×200 + 11×502 sin header. PDF corrupto: 422 en extractor → 502 en el API. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | El cliente trata saturación como fallo y empeora la cola. |
| **Descubrimiento** | Prueba de saturación con `curl` concurrente (2026-10-18). |
| **Causa raíz** | `RC-007` |
| **Acción** | Propagar 4xx/503 (con `Retry-After`) y reservar 502 a red/timeout/500 del upstream. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (API `fb3d7c3`, 2026-10-19) |
| **Restricciones** | Resuelto en la fase de correcciones aprobada. |

### FIND-013

| Campo | Valor |
|---|---|
| **ID** | `FIND-013` |
| **Título** | Un id malformado en `GET /documents/{id}` respondía 500 en el API |
| **Etapa** | Etapa 2 (2026-10-18) |
| **Categoría** | contrato / errores |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `internal/services/persistence_client.go:106-111`; `internal/api/documents.go:52-58` |
| **Descripción** | Persistence devuelve 400 `INVALID_REQUEST`; el cliente no lo propagaba y caía al 500 `INTERNAL_ERROR`. |
| **Evidencia** | `curl .../documents/xyz` → 500; id válido inexistente → 404 correcto (runtime 2026-10-18). |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | Un error de cliente se reporta como fallo interno. |
| **Descubrimiento** | Trazado del CRUD en la Etapa 2. |
| **Causa raíz** | `RC-007` |
| **Acción** | Validar el id en la API y re-emitir 4xx del upstream. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (API `fb3d7c3`, 2026-10-19) |
| **Restricciones** | Resuelto en la fase de correcciones aprobada. |

### FIND-014

| Campo | Valor |
|---|---|
| **ID** | `FIND-014` |
| **Título** | La API no propagaba `X-Request-ID` a Persistence |
| **Etapa** | Etapa 2 (2026-10-18) |
| **Categoría** | observabilidad / trazabilidad |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `internal/services/persistence_client.go` vs `extraction_client.go:62-64` y `persistence/internal/api/middleware.go:32-49` |
| **Descripción** | El cliente de Persistence nunca enviaba el header; Persistence generaba otro UUID y la correlación se rompía. |
| **Evidencia** | `curl ... -H 'X-Request-ID: etapa2-audit-001'` → los logs de Persistence no contienen ese id (runtime 2026-10-18). |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | No se puede rastrear una petición en los 4 servicios con un id. |
| **Descubrimiento** | Verificación de correlación en la Etapa 2. |
| **Causa raíz** | `RC-008` |
| **Acción** | Enviar `X-Request-ID` en los 5 métodos del cliente de Persistence. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (API `fb3d7c3`, 2026-10-19) |
| **Restricciones** | Resuelto en la fase de correcciones aprobada. |

### FIND-015

| Campo | Valor |
|---|---|
| **ID** | `FIND-015` |
| **Título** | El 503 de saturación declaraba `code: "INTERNAL_ERROR"` |
| **Etapa** | Etapa 2 (2026-10-18) |
| **Categoría** | contrato / errores |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-extractor` |
| **Ubicación** | `admission.py:45-51`; `errors.py` (catálogo sin entrada de saturación) |
| **Descripción** | El catálogo no tenía code de saturación y el 503 reutilizaba `INTERNAL_ERROR`; un cliente que decide por `code` trataba una condición transitoria como fallo permanente. |
| **Evidencia** | `admission.py:45-51` devolvía `INTERNAL_ERROR` con header `Retry-After`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Semántica de error engañosa. |
| **Descubrimiento** | Revisión de contratos de error (Etapa 2). |
| **Causa raíz** | `RC-009` |
| **Acción** | Code dedicado `SERVICE_OVERLOADED` en el catálogo. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (extractor `627aecf`, 2026-10-19) |
| **Restricciones** | Resuelto junto con RFC 9457 (`CON-018`). |

### FIND-016

| Campo | Valor |
|---|---|
| **ID** | `FIND-016` |
| **Título** | `page.get_text("dict")` decodificaba las imágenes embebidas que luego se descartaban |
| **Etapa** | Etapa 3A (2026-10-19) |
| **Categoría** | rendimiento — cuello de botella verificado |
| **Severidad** | Alta |
| **Repositorio** | `pdf-extractext-extractor` |
| **Ubicación** | `domain/extractor.py:70` (`get_text("dict")` sin `flags`, incluía `TEXT_PRESERVE_IMAGES`) y `:83-84` (descarte de bloques `type != 0`) |
| **Descripción** | Los flags por defecto (`TEXTFLAGS_DICT`) hacían que MuPDF decodificara las imágenes de cada página (bloques `type != 0`) que el conversor descarta siempre. Coste alto sin efecto en la salida. |
| **Evidencia** | A/B en el host de auditoría (mismo PDF, misma función): heavy/90 pág 6,276 s → 0,438 s (14,3×); historias 4,4×; Lean 1,5×; Scrum 1,0×. Markdown **idéntico byte a byte en los 5 PDFs**. Desglose heavy: abrir/recorrer 0,007 s, `get_text()` plano 0,19–0,34 s, `get_text("dict")` 6,0–6,7 s, conversión ≈0,1 s. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` + `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Coste CPU por request multiplicado (≈4×–14× según imágenes) con salida idéntica; invalida las cifras absolutas de Issue #9/ADR 0002 (previas al Markdown). |
| **Descubrimiento** | Etapa 3A, bloque de algoritmo/coste del hot path. |
| **Causa raíz** | `RC-010` |
| **Acción** | `TEXTFLAGS_DICT & ~TEXT_PRESERVE_IMAGES`. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-19) — `domain/extractor.py:68-70`; valida la suite de dominio (Markdown esperado) + `TestImageBlocksAreSkipped` (spy de los flags). |
| **Restricciones** | Los tiempos absolutos no son comparables con Issue #9 (specs del host desconocidas): solo ratios intra-máquina. |

### FIND-017

| Campo | Valor |
|---|---|
| **ID** | `FIND-017` |
| **Título** | La extracción CPU-bound corría en el event loop: bloqueaba `/health` y la admisión |
| **Etapa** | Etapa 3A (2026-10-19) |
| **Categoría** | arquitectura / concurrencia — cuello de botella verificado |
| **Severidad** | Alta |
| **Repositorio** | `pdf-extractext-extractor` |
| **Ubicación** | `extraction.py:112` (llamada síncrona dentro de `async def extract`); `admission.py:42-58`; `gunicorn.conf.py:8` (backlog 64) |
| **Descripción** | Sin offload, mientras PyMuPDF trabajaba el worker no atendía nada: concurrencia efectiva 1, `/health` y `/readyz` en cola, y el 503 solo alcanzaba a las peticiones que llegaban con el loop libre (las del backlog esperaban en serie). |
| **Evidencia** | `/health` retrasado ~11,6 s durante una extracción in-process; 3 solicitudes simultáneas → 1×200 + 2×503; petición lanzada con el loop bloqueado → 200 a los 7,46 s (serializada) en vez de 503. Grep: sin `threading`/`to_thread`/`ProcessPool` en `src/`. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` + `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Sin paralelismo real, backpressure parcial (la mayoría del tráfico saturado esperaba y podía superar el timeout de 30 s del API → 502), healthchecks en riesgo y trabajos no cancelables. |
| **Descubrimiento** | Etapa 3A, bloque de concurrencia/workers. |
| **Causa raíz** | `RC-011` (complementa `FIND-012`) |
| **Acción** | Delegar a `run_in_threadpool` manteniendo el semáforo como límite de slots. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-19) — `extraction.py:15,93-94`; `tests/api/test_concurrency.py` (2 tests: `/health` responde y el 503 es inmediato con la extracción en curso; ambos fallan si se revierte el fix). |
| **Restricciones** | Si PyMuPDF no libera el GIL, el paralelismo CPU sigue limitado (pendiente de verificar en la etapa de benchmarks). |

### FIND-018

| Campo | Valor |
|---|---|
| **ID** | `FIND-018` |
| **Título** | Un PDF protegido con contraseña respondía 500 (y 502 vía API) en vez de 4xx |
| **Etapa** | Etapa 3A (2026-10-19) |
| **Categoría** | contrato / errores |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-extractor` (+ `pdf-extractext-api`) |
| **Ubicación** | `domain/extractor.py:55` (`except` solo cubre `FileDataError`/`EmptyFileError`); el `ValueError: document closed or encrypted` caía en el `except Exception` |
| **Descripción** | `pymupdf.open` acepta el PDF cifrado y el fallo aparece al recorrer páginas; el catch específico no lo cubría → `InternalProcessingError` → 500, y el API lo traducía a 502. Un PDF con contraseña es un 4xx de cliente. |
| **Evidencia** | PDF generado con `PDF_ENCRYPT_AES_256` (user_pw) → `InternalProcessingError` → 500 (`audit_3a_probe`); sin test previo de cifrado (grep `encrypt/password/needs_pass` en `tests/` → 0). |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | Contamina los 5xx con tráfico inválido; el usuario no recibe indicación accionable. |
| **Descubrimiento** | Etapa 3A, matriz de PDFs inválidos. |
| **Causa raíz** | `RC-012` |
| **Acción** | Detectar `document.needs_pass` y mapearlo a 422 `INVALID_PDF_CONTENT` (sin code nuevo). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-19) — `domain/extractor.py:49-51`; tests `TestEncryptedPdf` (dominio) y `test_encrypted_pdf_maps_to_422` (API). |
| **Restricciones** | Solo verificado AES-256 con contraseña de usuario; otros esquemas quedan como hueco. |

### FIND-019

| Campo | Valor |
|---|---|
| **ID** | `FIND-019` |
| **Título** | Sin límite de expansión/páginas/tiempo y ≥2 copias del binario en RAM → riesgo de OOMKill |
| **Etapa** | Etapa 3A (2026-10-19) |
| **Categoría** | rendimiento / robustez |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-extractor` |
| **Ubicación** | `config.py:14` (solo `max_upload_bytes`); `extraction.py` (recepción 100 % en memoria, spool nunca cerrado); Compose `memory: 1G` |
| **Descripción** | El límite defensivo acota el input comprimido, no la expansión de PyMuPDF; tampoco hay tope de páginas ni de tiempo, y durante la fase CPU coexisten el spool y `pdf_bytes`. Lo que sí es correcto: cero archivos temporales y cierre garantizado del documento. |
| **Evidencia** | Pico Python 20,7 MiB para 8,49 MiB de entrada (~2,4×), 1,25 MiB al final; `pymupdf/__init__.py:2979` abre el stream sin copia; OOM previo documentado en `performance-issue-9.md:22-25`. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` + `[VERIFICADO-CÓDIGO]` + `[HIPÓTESIS]` (OOM con PDF bomba) |
| **Impacto** | Un PDF que expanda mucho puede tumbar la réplica (1 worker) con 1 GiB de límite y provocar 502 masivos. |
| **Descubrimiento** | Etapa 3A, bloques de memoria y archivos inválidos. |
| **Causa raíz** | `RC-013` |
| **Acción** | Liberar el spool con `await upload.close()` (hecho). Pendiente: límites de páginas/tiempo y techo de memoria (decisión del equipo). |
| **Estado** | **Parcial** (2026-10-19) — `extraction.py:87-89` cierra el `UploadFile` tras leer; los límites de expansión/páginas/tiempo siguen abiertos. |
| **Restricciones** | No se probaron PDFs bomba (prueba destructiva). Sin `/proc`/`docker stats`, el RSS real no es medible en esta etapa. |

### FIND-020

| Campo | Valor |
|---|---|
| **ID** | `FIND-020` |
| **Título** | La respuesta duplica el Markdown (`extracted_text` == `content`) |
| **Etapa** | Etapa 3A (2026-10-19) |
| **Categoría** | contrato / rendimiento |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-extractor` + `pdf-extractext-api` |
| **Ubicación** | `extraction.py:96-99` (ambas claves con el mismo string); `internal/services/extraction_client.go:15-16`; `internal/api/extract.go:47-48` (solo publica `content`) |
| **Descripción** | El contrato fija `extracted_text == content`: el Markdown viaja dos veces y en `/extract` un campo nunca se consume. |
| **Evidencia** | Markdown 121,3 KiB → cuerpo de respuesta 0,242 MiB (≈2×). |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` + `[VERIFICADO-CÓDIGO]` |
| **Impacto** | ~2× de payload y de serialización; proporcional al documento. |
| **Descubrimiento** | Medición de memoria/respuesta en la Etapa 3A. |
| **Causa raíz** | `RC-014` |
| **Acción** | Reabrir la decisión D14/INT-01 (un solo campo o campos a demanda). |
| **Estado** | Abierto — `[DECISIÓN-PENDIENTE]` |
| **Restricciones** | No se modifica el contrato acordado. |

### FIND-021

| Campo | Valor |
|---|---|
| **ID** | `FIND-021` |
| **Título** | Los defaults de workers seguían en 4 (medido como peor) mientras ADR 0002 fija 1 |
| **Etapa** | Etapa 3A (2026-10-19) |
| **Categoría** | configuración / documentación |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-extractor` |
| **Ubicación** | `gunicorn.conf.py:5` (default 4); `docker-compose.yml:12` (`WEB_CONCURRENCY: "4"`); `README.md` ("4 × 1 = 4"); vs ADR 0002 e Infrastructure (`EXTRACTION_WORKERS=1`) |
| **Descripción** | La decisión medida (1 worker × 1 slot) solo se aplicaba en Infrastructure vía env; el arranque local reproducía la configuración descartada. |
| **Evidencia** | `performance-issue-9.md:57` (4 workers: RSS 601 MiB, p99 2,91 s) vs `:58` (1 worker: 190 MiB, 0,37 s). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Mediciones/smokes locales no representaban producción. |
| **Descubrimiento** | Etapa 3A, bloque de concurrencia/workers. |
| **Causa raíz** | `RC-015` (+ `RC-010`) |
| **Acción** | Alinear defaults a 1. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-19) — `gunicorn.conf.py:5`, `docker-compose.yml:12`, `README.md`; `tests/test_container_config.py` sigue verde. |
| **Restricciones** | En Infrastructure la configuración ya era correcta. |

### FIND-022

| Campo | Valor |
|---|---|
| **ID** | `FIND-022` |
| **Título** | `settings.port` muerto y puerto documentado (8000) distinto del real (8001) |
| **Etapa** | Etapa 3A (2026-10-19) |
| **Categoría** | configuración / documentación |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-extractor` |
| **Ubicación** | `config.py:13` (`port`, sin lectores); `gunicorn.conf.py:7` (`PORT` default 8001); `Dockerfile:32`; `README.md` |
| **Descripción** | Ningún código leía `settings.port`; el bind real es 8001. Un lector podía creer que configurar la app cambiaba el puerto. |
| **Evidencia** | Grep `settings.port` en `src/` → 0 resultados; README documentaba 8000. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Nulo en runtime; confusión operativa/documental. |
| **Descubrimiento** | Etapa 3A, verificación de la ruta de arranque. |
| **Causa raíz** | `RC-005` |
| **Acción** | Eliminar `settings.port` y unificar el puerto documentado en 8001. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-19) — `config.py` (setting eliminada), `README.md` (tabla y ejemplos a 8001). |
| **Restricciones** | — |
