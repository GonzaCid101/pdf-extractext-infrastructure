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
| `RC-014` | El contrato exige `extracted_text == content`: el Markdown viaja dos veces. | `FIND-020` | Resuelta (decisión de equipo: se conserva) | `[VERIFICADO-PRUEBA]` |
| `RC-015` | Los defaults de arranque del extractor nunca se alinearon con la decisión medida del ADR 0002 (1 worker). | `FIND-021` | Resuelta (2026-10-19) | `[VERIFICADO-CÓDIGO]` |
| `RC-016` | La API no tiene contrapresión propia: no limita tasa ni conexiones concurrentes hacia Extraction/Persistence. | `FIND-023` | Resuelta (decisión de equipo: backpressure en Extraction, ADR D10) | `[VERIFICADO-CÓDIGO]` |
| `RC-017` | El cliente HTTP de la API usa el `DefaultTransport` de Go (2 conexiones inactivas por host): bajo carga no sostiene keep-alive y abre/destruye sockets. | `FIND-024` | Resuelta (2026-10-19) | `[VERIFICADO-CÓDIGO]` |
| `RC-018` | Sin timeout de lectura/escritura en `http.Server` de Persistence y sin `IdleTimeout`/`ReadTimeout` en ninguno de los dos servicios Go. | `FIND-025`, `FIND-031` | Resuelta (2026-10-19) | `[VERIFICADO-CÓDIGO]` |
| `RC-019` | Deriva interna de Persistence: código legado de la issue #3 convive con el activo, el repo no sincronizó las correcciones registradas (RFC 9457, README) y arrastra comentarios verbosos/IDs de auditoría. | `FIND-026`, `FIND-027`, `FIND-028`, `FIND-029` | Resuelta (2026-10-19) | `[VERIFICADO-CÓDIGO]` |
| `RC-020` | La imagen runtime de API usa distroless base (root); el usuario final nunca se revisó con `docker inspect`. | `FIND-032` | Resuelta (2026-10-20) | `[VERIFICADO-PRUEBA]` |
| `RC-021` | El apagado ordenado no fue criterio de aceptación: la API no captura señales y el compose no fija `stop_grace_period`. | `FIND-033`, `FIND-034` | Resuelta (2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-022` | Traefik quedó con la configuración mínima (routers+TLS): sin healthcheck HTTP, sin timeouts de reenvío ni límite de cuerpo; la capa efectiva la ponen los timeouts del cliente API. | `FIND-035` | Aceptada por diseño (ADR D19, 2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-023` | El dashboard de Traefik se habilitó para desarrollo local sin política de acceso. | `FIND-036` | Resuelta (2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-024` | Nombres de proyecto/red y credenciales quedaron acoplados entre `traefik.yml`, compose y smoke, con defaults inconsistentes. | `FIND-037`, `FIND-038` | Resuelta/aceptada (2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-025` | Los scripts de verificación se escribieron para 1 réplica y no se actualizaron con la exigencia de escala 1–5. | `FIND-039` | Resuelta (2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-026` | La documentación pública no se actualizó al 100% tras 3A/3B (OpenAPI incompleto; README/env de API local con valores de arranque). | `FIND-040`, `FIND-041` | Resuelta (2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-027` | Deuda de Clean Code heredada del bootstrap: IDs de issues en Dockerfiles/scripts y targets duplicados en Makefiles. | `FIND-042`, `FIND-046` | Resuelta / diferida a Etapa 4 (2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-028` | Endurecimiento de imágenes/.dockerignore definido por repo, sin estándar mínimo común (digests, USER, exclusiones). | `FIND-043`, `FIND-044` | Resuelta/aceptada (2026-10-20) | `[VERIFICADO-CÓDIGO]` |
| `RC-029` | El estado del host se apartó de lo declarado (Traefik del proyecto sin red/puertos; Traefik ajeno reteniendo 80/443) sin registro. | `FIND-045` | Resuelta (2026-10-20) | `[VERIFICADO-PRUEBA]` |
| `RC-030` | Los scripts de carga se escribieron contra una versión de Vegeta anterior a v12 (`>=12.8`), que ya no acepta el body embebido en targets `http`; las herramientas nunca se instalaron en el host, así que el fallo no se detectó. | `FIND-048` | Abierta (Etapa 4) | `[VERIFICADO-PRUEBA]` |
| `RC-031` | `run_k6.sh` usa `--summary-export`, retirado en k6 v2.x; el resumen nunca se genera y el wrapper silencia la ausencia devolviendo ceros. | `FIND-049` | Abierta (Etapa 4) | `[VERIFICADO-CÓDIGO]` |
| `RC-033` | `run_k6.sh` no exportaba `BASE_URL` derivado de `TARGET_URL`; k6 usaba su default y la perilla de destino era ignorada. | `FIND-053` | Resuelta (Etapa 4) | `[VERIFICADO-PRUEBA]` |
| `RC-034` | `mock_api.py` hardcodeaba `page_count: 0`, incompatible con el check `page_count > 0` de k6. | `FIND-054` | Resuelta (Etapa 4) | `[VERIFICADO-PRUEBA]` |

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
| **Ubicación** | `Makefile:57-58` → `tests/load/run_k6.sh` → `tests/load/spike_tests.js` (stages 100 VUs); `k6-spike.js` (100 VUs) eliminado el 2026-10-18. |
| **Descripción** | El README describe "spike 10s→100 VUs" pero `spike_tests.js` subía a 1 VU. Decisión del equipo: `spike_tests.js` es el canónico; las stages de 100 VUs se implementan al final del ciclo. |
| **Evidencia** | **Corrección 2026-10-21:** `spike_tests.js` con stages `10s→100, 20s→100, 10s→0` parametrizables por `TARGET_VUS`; `k6 inspect` confirma `target: 100` (y `10` con `-e TARGET_VUS=10`). Validado contra `tests/load/mock_api.py` (8 reqs, `extract_ok` 100 %, p50/p90/p95 no-cero). La **medición real** sobre el stack queda pendiente de validación. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` (mock oficial) |
| **Impacto** | El benchmark cableado ahora reproduce el escenario del TP (100 VUs). |
| **Descubrimiento** | Lectura cruzada Makefile → scripts k6 vs enunciado. |
| **Causa raíz** | `RC-003` |
| **Acción** | Hecho: stages 100 VUs implementadas y validadas contra mock. Falta la corrida real. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-21; lógica del perfil validada contra mock; cifras reales pendientes de validación) |
| **Restricciones** | Corrida real pendiente de ejecución. |

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
| **Ubicación** | `tests/load/vegeta/run_vegeta.sh` (`RATE`/`-rate`); README `:76`; D11 `:71` |
| **Descripción** | `RATE` estaba hardcoded a `1/s` (sin default sobreescribible), mientras script, README y ADR documentan 50 req/s. |
| **Evidencia** | **Corrección 2026-10-21:** `RATE="${RATE:-50/s}"`, `DURATION="${DURATION:-30s}"`, `TIMEOUT="${TIMEOUT:-30s}"`. Objetivo 50×30 = 1.500 reqs. Validado contra `tests/load/mock_api.py` (30 reqs a 10/s, éxito 100 %, `bad:0`) y contra stub local a 50/s (150/150 reqs en 3 s). La medición real queda pendiente de validación. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` + `[VERIFICADO-PRUEBA]` (mock oficial) |
| **Impacto** | Corridas comparables con la referencia del TP (1.500 reqs). |
| **Descubrimiento** | Contraste comentario/README/ADR vs valor de `RATE`. |
| **Causa raíz** | `RC-003` |
| **Acción** | Hecho: rate corregido a 50/s y validado contra mock. Falta corrida real. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-21; perfil validado contra mock; cifras reales pendientes de validación) |
| **Restricciones** | Corrida real pendiente de ejecución. |

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

### FIND-023

| Campo | Valor |
|---|---|
| **ID** | `FIND-023` |
| **Título** | La API no tiene backpressure propio (sin rate limiting ni límite de concurrencia) |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | arquitectura / sobrecarga |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `cmd/api/main.go:24-40` (sin middleware de límite ni `limiter`); único límite = `BodyLimit` (`main.go:26`) |
| **Descripción** | La API es un proxy sin contrapresión: acepta 100 VUs simultáneos y reenvía todo a Extraction/Persistence. El límite de 30 s es solo por request, no acota concurrencia ni tasa; bajo carga el backpressure efectivo queda delegado (y solo) en el 503 de Extraction. |
| **Evidencia** | `main.go` registra `RequestID` y rutas, sin `limiter.New` ni semáforo; `extraction_client.go:36` usa `http.Client` sin `MaxConnsPerHost`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo el spike de 100 VUs, el exceso de tráfico se intenta reenviar en vez de rechazarse en el borde; el usuario final recibe 503/502/timeout en lugar de un rechazo temprano controlado (429). |
| **Descubrimiento** | Etapa 3B, bloque de orquestación/sobrecarga de API. |
| **Causa raíz** | `RC-016` |
| **Acción** | No se añade rate limiter/semáforo: el control de admisión vive en `Extraction` (503 + `Retry-After`, ADR D10), escalable 1→5 réplicas (`ASK-010`). |
| **Estado** | Resuelto (decisión de equipo, 2026-10-19) |
| **Restricciones** | Cambio de comportamiento descartado por decisión. |

### FIND-024

| Campo | Valor |
|---|---|
| **ID** | `FIND-024` |
| **Título** | Los clientes HTTP de la API usan el `DefaultTransport` (2 conexiones keep-alive por host) |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | rendimiento / concurrencia |
| **Severidad** | Alta |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `internal/services/extraction_client.go:33-38` y `persistence_client.go:51-56` (`&http.Client{Timeout: …}` sin `Transport`) |
| **Descripción** | Al no definir `Transport`, Go usa `http.DefaultTransport`: `MaxIdleConnsPerHost = 2` (`net/http/transport.go:62`). El cliente **no crea una conexión nueva por request** (reutiliza keep-alive), pero con >2 ejecuciones concurrentes por host las conexiones sobrantes se abren, se usan y se tienen que cerrar en vez de reutilizarse. |
| **Evidencia** | `GOROOT/src/net/http/transport.go:54-62`: `MaxIdleConns:100`, `MaxIdleConnsPerHost:2`, `IdleConnTimeout:90s`. Bajo 100 VUs contra 1 host → churn de sockets y consumo de puertos efímeros/`TIME_WAIT`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` (fuente: stdlib) |
| **Impacto** | Overhead de conexión por request bajo carga; no hay fuga (keep-alive sí funciona), pero el pool por defecto es pequeño para el escenario de 100 VUs. Mitigable sin tocar la lógica: `Transport` con `MaxIdleConnsPerHost`/`MaxConnsPerHost` explícitos. |
| **Descubrimiento** | Etapa 3B, bloque de cliente HTTP. |
| **Causa raíz** | `RC-017` |
| **Acción** | `Transport` compartido con `MaxIdleConns`/`MaxIdleConnsPerHost = 100` e `IdleConnTimeout` explícitos en ambos clientes. |
| **Estado** | Resuelto (implementado 2026-10-19) |
| **Restricciones** | — |

### FIND-025

| Campo | Valor |
|---|---|
| **ID** | `FIND-025` |
| **Título** | Sin timeouts de servidor (`ReadTimeout`/`IdleTimeout`) en API; sin `ReadTimeout`/`IdleTimeout` en Persistence |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | robustez / configuración |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api`, `pdf-extractext-persistence` |
| **Ubicación** | `api cmd/api/main.go:43` (`app.Listen` sin `ReadTimeout`/`IdleTimeout`); `persistence cmd/api/main.go:45-49` (`http.Server` con solo `ReadHeaderTimeout`) |
| **Descripción** | Falta `IdleTimeout` en ambos y `ReadTimeout` en Persistence. Bajo 100 VUs con keep-alive, una conexión ociosa puede retener recursos más de lo previsto; en fasthttp se configura con `IdleTimeout` en `fiber.Config`. |
| **Evidencia** | `persistence/main.go:48` solo fija `ReadHeaderTimeout: 5s`; `api/main.go:24` config sin timeouts de idle/read. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Riesgo de acumulación de conexiones lentas/idle bajo carga sostenida; relacionado con `HYP-08`. |
| **Descubrimiento** | Etapa 3B, bloque de configuración de servidor. |
| **Causa raíz** | `RC-018` |
| **Acción** | Añadidos `ReadTimeout`/`WriteTimeout`/`IdleTimeout` explícitos en API (Fiber) y Persistence (`http.Server`). |
| **Estado** | Resuelto (implementado 2026-10-19) |
| **Restricciones** | — |

### FIND-026

| Campo | Valor |
|---|---|
| **ID** | `FIND-026` |
| **Título** | Comentarios/contrato de error documentados como RFC 9457 pero el código de Persistence sigue con envelope `{code,message}` y comentarios en contradicción |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | documentación / contrato |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-persistence` |
| **Ubicación** | `internal/api/errors.go:23-24` ("Sin RFC 9457") vs README/CON-018 (adopción RFC 9457); `internal/api/documents.go:84-97` (comentario de doble formato de error) |
| **Descripción** | El repo Persistence **no contiene** el commit `2af0e62` ni `internal/api/errors.go` con `problemResponse`/`problemCatalog` que el registro de auditoría (C-22/CON-018) da por implementados: citó código de una rama que no está en `main` de este clon. El envelope real es `{code,message}` (sin `type`/`title`/`status`), y los comentarios lo declaran "Sin RFC 9457". |
| **Evidencia** | `git log --all --oneline` de Persistence no encuentra `2af0e62`; grep `problemCatalog\|problemResponse\|application/problem+json` → 0 resultados en el repo. El commit de API `fb3d7c3` sí existe; el de Persistence no. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | La afirmación `[RESUELTA]` de `CON-018` no es reproducible en Persistence: su envelope no cumple RFC 9457. Afecta a la validez del registro de decisiones. |
| **Descubrimiento** | Etapa 3B, verificación cruzada del registro de correcciones contra los repos. |
| **Causa raíz** | `RC-019` |
| **Acción** | `git pull` del equipo trajo `2af0e62` a `main`: `problemCatalog`/`problemResponse` (`application/problem+json`) presentes. `CON-018` válido. |
| **Estado** | Resuelto (2026-10-19, por sincronización del clon) |
| **Restricciones** | — |

### FIND-027

| Campo | Valor |
|---|---|
| **ID** | `FIND-027` |
| **Título** | Código muerto y tipo duplicado en Persistence (`PDFRepository`, `DomainToMongo`/`MongoToDomain`, `PDFDocument`, `existingToResponse`) |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | clean code / mantenibilidad |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-persistence` |
| **Ubicación** | `internal/repository/pdf_repository.go` (todo el archivo, sin llamadores de producción); `internal/infra/mongo/pdfdocument_mapper.go` (`DomainToMongo`/`MongoToDomain`, solo usados por `pdf_repository`); `internal/domain/pdfdocument.go` (`PDFDocument`, `DuplicateChecksumError`); `internal/api/documents.go:51-60` (`existingToResponse` usado solo desde `createDocumentHandler` por `DuplicateChecksumError`) |
| **Descripción** | Hay **dos** repositorios y **dos** modelos de documento coexistiendo: el activo (`Document`, `DocumentRepository`, `documentFromBSON`) y el legado de la issue #3 (`PDFRepository`, `PDFDocument`, `DomainToMongo`/`MongoToDomain`). El 409 recupera el documento con `documentFromBSON` y luego lo convierte con `existingToResponse`, puente que conecta ambos mundos. |
| **Evidencia** | Grep de llamadores de producción: `NewPDFRepository` → 0 fuera de tests + `repository`; `DomainToMongo`/`MongoToDomain` → solo `pdf_repository.go`. El wiring real (`cmd/api/main.go:43`) usa `mongo.NewDocumentRepository`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Doble mantenimiento y confusión sobre cuál es la fuente de verdad del mapeo; los tests de integración podrían estar cubriendo la ruta muerta. |
| **Descubrimiento** | Etapa 3B, revisión de Clean Code de Persistence. |
| **Causa raíz** | `RC-019` |
| **Acción** | Eliminado el legado (`repository/pdf_repository.go`, `pdfdocument_mapper.go`, `PDFDocument`, `existingToResponse`); `DuplicateChecksumError.Existing` migrado a `domain.Document`. |
| **Estado** | Resuelto (implementado 2026-10-19) |
| **Restricciones** | — |

### FIND-028

| Campo | Valor |
|---|---|
| **ID** | `FIND-028` |
| **Título** | Comentarios verbosos, comentarios de auditoría embebidos en el código y configuración muerta |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | clean code / documentación |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-api`, `pdf-extractext-persistence` |
| **Ubicación** | `extraction_client.go:13,36,60`; `persistence_client.go:36,58,136`; `upload_pdf.go:13-14,56`; `documents.go:11-12,27-28`; `errors.go:53`; `persistence documents.go:18-19,26-31,51-52,84-85,93-94`; `persistence middleware.go:28-31,39-40,52-55`; `api main.go:27` (comentario "{\"code\",\"message\"}" describe el catálogo viejo) |
| **Descripción** | Hay (a) comentarios que referencian IDs de auditoría (`FIND-012/013/014`) que no deben quedar en el código fuente; (b) comentarios que describen la implementación, no el "porqué", duplicando el nombre de la función; (c) en `mongo/pdfdocument_mapper.go`/`document_repository.go` hay bloques anti-TOCTOU repetidos. |
| **Evidencia** | Grep `FIND-01` en `*.go` de ambos repos → múltiples coincidencias en API y Persistence; comentarios de 3-5 líneas en `persistence client.go:28-33`, `documents.go:18-19`. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Ruido y deuda de mantenibilidad; los IDs de auditoría en código se vuelven obsoletos. |
| **Descubrimiento** | Etapa 3B, revisión de Clean Code. |
| **Causa raíz** | `RC-019` |
| **Acción** | Eliminados los IDs `FIND-XXX`/`Issue #N` y los comentarios redundantes; quedan solo comentarios de 1 línea con el *porqué*. |
| **Estado** | Resuelto (implementado 2026-10-19) |
| **Restricciones** | — |

### FIND-029

| Campo | Valor |
|---|---|
| **ID** | `FIND-029` |
| **Título** | README de Persistence describe el estado de bootstrap (CRUD "en etapas posteriores") |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | documentación |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-persistence` |
| **Ubicación** | `README.md:5` ("El CRUD y el repositorio se implementarán en etapas posteriores"), `README.md:137-139` (estructura solo `GET /health`) |
| **Descripción** | El README contradice el código real (CRUD completo en `router.go:26-37`, `/health/ready`, `/readyz`). Es una regresión respecto de la corrección `FIND-004`/C-16, probablemente porque el README se reescribió a un estado anterior en este clon. |
| **Evidencia** | `router.go:26-30` registra POST/GET/PATCH/DELETE `/documents`; README:5 dice lo contrario. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Documentación engañosa para quien clone el repo. |
| **Descubrimiento** | Etapa 3B, contraste README ↔ router. |
| **Causa raíz** | `RC-019` |
| **Acción** | README al día tras el `git pull` (describe CRUD + probes). |
| **Estado** | Resuelto (2026-10-19, por sincronización del clon) |
| **Restricciones** | — |

### FIND-030

| Campo | Valor |
|---|---|
| **ID** | `FIND-030` |
| **Título** | Pico de memoria de la API: el buffer multipart full-body + `BodyLimit` de 50 MB permiten ~70 MB residentes por request |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | rendimiento / memoria |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api` (+ Infrastructure) |
| **Ubicación** | `cmd/api/main.go:26` (`BodyLimit = MAX_FILE_SIZE_MB*MiB`); `docker-compose.yml:39` (`MAX_FILE_SIZE_MB=50`); `docker-compose.yml` (límite `memory: 512M` de api) |
| **Descripción** | fasthttp **bufferiza el body completo en RAM** antes de parsear el multipart (`http.go:1254` → `readMultipartForm` → `multipart.NewReader`), en contra de la creencia de "streaming 100 % en memoria sin materializar". El archivo se reenvía luego a Extraction por `io.Pipe` (eso sí es streaming de salida), pero la entrada ya está íntegra en memoria. Con `BodyLimit=50 MB` (compose) el peor caso ronda los ~70 MB por request (buffer de cuerpo + buffer de trabajo multipart + copia de la parte). |
| **Evidencia** | `fasthttp@v1.51.0/http.go:1240-1259`: con `contentLength>0` hace `readMultipartForm(r, boundary, contentLength, defaultMaxInMemoryFileSize=16MiB)`; el archivo >16 MiB va a **spool en disco temporal** (no a disco del PDF en sí, sino `os.TempDir`), contradiciendo también el README ("cero volcados a disco"). 100 VUs × 50 MB no caben en 512 MiB. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo el spike de 100 VUs con PDFs grandes, la API puede llegar a OOMKill (límite 512 MiB) o provocar swap/presión de memoria antes que Extraction sea el cuello. Además, el README de API afirma "cero volcados a disco" pero fasthttp sí hace spool >16 MiB. |
| **Descubrimiento** | Etapa 3B, verificación del procesamiento del archivo entrante. |
| **Causa raíz** | `RC-016` (combinado con el límite de 50 MB del compose) |
| **Acción** | `MAX_FILE_SIZE_MB` fijado a 16 (umbral `defaultMaxInMemoryFileSize`) en config, `.env.example` y compose; README de API corregido (spool >16 MiB). |
| **Estado** | Resuelto (implementado 2026-10-19) |
| **Restricciones** | No se ejecutaron cargas; el cálculo es analítico sobre el código de fasthttp. |

### FIND-031

| Campo | Valor |
|---|---|
| **ID** | `FIND-031` |
| **Título** | El timeout de `uploadTimeout` se activa como 504 en el camino del extractor, pero el error de deadline del cliente HTTP puede mapearse a 502 |
| **Etapa** | Etapa 3B (2026-10-19) |
| **Categoría** | contrato / errores |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `internal/api/upload_pdf.go:52-58`; `internal/services/extraction_client.go:66-68` |
| **Descripción** | El `http.Client` de Extraction tiene `Timeout: 30s` (línea 36) **y** el handler aplica además un `context.WithTimeout(30s)` (upload_pdf.go:48). Cuando el `http.Client.Timeout` dispara, el error devuelto es `*url.Error` envolviendo un error que satisface `net.Error.Timeout()` pero **no** necesariamente `context.DeadlineExceeded`; el handler comprueba `errors.Is(err, context.DeadlineExceeded)` y, si no coincide, cae a `respondUpstream` → 502 en vez del 504 `GATEWAY_TIMEOUT` documentado. |
| **Evidencia** | El test `TestExtractionClient_Timeout` (extraction_client_test.go:64-75) solo verifica `require.Error`, sin aserta el tipo ni el status resultante. No hay test que fije el 504 end-to-end por timeout de cliente. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Un timeout del extractor puede reportarse como 502 en lugar de 504 según qué capa dispare primero; el contrato OpenAPI/README promete 504. |
| **Descubrimiento** | Etapa 3B, revisión del manejo de fallos parciales. |
| **Causa raíz** | `RC-018` |
| **Acción** | Helper `isTimeout` (`context.DeadlineExceeded`/`os.ErrDeadlineExceeded`/`net.Error.Timeout`) unifica el mapeo a 504 en upload/extract; tests de timeout de red y E2E. |
| **Estado** | Resuelto (implementado 2026-10-19) |
| **Restricciones** | — |

### FIND-032

| Campo | Valor |
|---|---|
| **ID** | `FIND-032` |
| **Título** | El contenedor de API corre como root; Persistence y Extraction corren non-root |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | seguridad / contenedores |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `Dockerfile:28` (`gcr.io/distroless/static-debian12` sin `:nonroot`, sin `USER`); contraste `persistence/Dockerfile:19,25` (`:nonroot` + `USER nonroot`), `extractor/Dockerfile:23,31` (`appuser` uid 10001) |
| **Descripción** | La variante base de distroless ejecuta como root; los otros dos servicios sí bajan de privilegios. `no-new-privileges` (compose) mitiga la escalada, pero el proceso sigue siendo uid 0. |
| **Evidencia** | `docker inspect pdf-extractext-api-1` → `Config.User=""`, ejecución efectiva `user=0`; persistence `user=nonroot`; extraction `user=appuser` (runtime 2026-10-19). |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | Superficie de privilegios innecesaria en el punto de entrada público si el binario es comprometido. |
| **Descubrimiento** | Etapa 3C, bloque de usuarios/seguridad de contenedores. |
| **Causa raíz** | `RC-020` |
| **Acción** | Usar `distroless/static-debian12:nonroot` + `USER nonroot` y verificar la ejecución del binario. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): imagen `distroless:nonroot` + `USER nonroot`. |
| **Restricciones** | Requiere rebuild de imagen (fase de correcciones). |

### FIND-033

| Campo | Valor |
|---|---|
| **ID** | `FIND-033` |
| **Título** | API sin graceful shutdown: no captura SIGTERM/SIGINT |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | robustez / operabilidad |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `cmd/api/main.go:46-49` (`app.Listen` sin manejo de señal); `Dockerfile:39` (`ENTRYPOINT ["/api"]` exec → PID 1 recibe SIGTERM) |
| **Descripción** | El proceso termina por disposición por defecto del runtime Go: las requests en vuelo se abortan en cada stop/re-escala/redeploy del contenedor de la API. |
| **Evidencia** | Grep `signal.Notify|SIGTERM|SIGINT` en `.go` de API → 0 en producción (solo `extract_test.go:103` llama `app.Shutdown()` en test). Contraste: persistence `cmd/api/main.go:54-77` (`signal.NotifyContext` + `srv.Shutdown` + `db.Disconnect`); extraction: `CMD ["gunicorn", …]` exec (`extractor/Dockerfile:37`) → gunicorn maneja SIGTERM. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Durante `docker compose stop`, re-escala o redeploy se pierden requests en curso (5xx o cortes para el cliente final). |
| **Descubrimiento** | Etapa 3C, verificación de señales de terminación. |
| **Causa raíz** | `RC-021` |
| **Acción** | `signal.NotifyContext` + `app.Shutdown()` con timeout. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): `signal.NotifyContext` + `app.ShutdownWithTimeout(10s)`. |
| **Restricciones** | — |

### FIND-034

| Campo | Valor |
|---|---|
| **ID** | `FIND-034` |
| **Título** | `stop_grace_period` default (10 s) menor que el graceful timeout de gunicorn (30 s) |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | operabilidad / configuración |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `docker-compose.yml` (sin `stop_grace_period` en ningún servicio); `pdf-extractext-extractor/gunicorn.conf.py` (sin `graceful_timeout`) |
| **Descripción** | Al parar o re-escalar Extraction, Docker envía SIGTERM y SIGKILL a los 10 s; una extracción larga en vuelo (hasta 30 s del lado del cliente API) sería asesinada en vez de drenada. |
| **Evidencia** | Grep `stop_grace_period` en compose → 0; `docker inspect` → `.HostConfig.StopGracePeriod` ausente (default 10 s); gunicorn `graceful_timeout` default 30 s. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` + `[HIPÓTESIS]` (el impacto depende de la duración en vuelo) |
| **Impacto** | Al bajar de 5→1 réplicas o en redeploy, trabajos en curso se pierden pese al manejo de SIGTERM de gunicorn. |
| **Descubrimiento** | Etapa 3C, cruce compose ↔ gunicorn. |
| **Causa raíz** | `RC-021` |
| **Acción** | `stop_grace_period: 35s` en extraction (y drenado acorde en api/persistence cuando `FIND-033` esté resuelto). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): `stop_grace_period` 35s (extraction) y 15s (api/persistence). |
| **Restricciones** | — |

### FIND-035

| Campo | Valor |
|---|---|
| **ID** | `FIND-035` |
| **Título** | Traefik sin healthcheck HTTP de backend, sin timeouts de reenvío ni límite de cuerpo |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | configuración / robustez del borde |
| **Severidad** | Baja (aceptado por diseño; falta documentarlo en el ADR) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `traefik/traefik.yml` (sin `serversTransport`/`transport`); `docker-compose.yml:80-84` (labels sin `loadbalancer.healthcheck.*`); healthcheck de extraction `docker-compose.yml:93-98` |
| **Descripción** | La exclusión de réplicas degradadas depende solo del healthcheck de Docker de la réplica (docs Traefik v3: con `allowEmptyServices=false` el provider excluye contenedores unhealthy). No hay tope de `responseHeaderTimeout` ni `maxRequestBodyBytes` en Traefik: la capa efectiva la pone el cliente de la API (30 s). |
| **Evidencia** | `traefik.yml` completo (35 líneas) sin sección de transport; grep `healthcheck|serversTransport` en labels del compose → solo `loadbalancer.server.port`. Ventana de exclusión ≈ intervalo 10 s × retries 5 + start (`docker-compose.yml:96-98`). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Una réplica unhealthy puede seguir en el pool hasta ~60 s; el borde no tiene tope propio de tiempo de respuesta (limitado por API 30 s e `IdleTimeout` 120 s). |
| **Descubrimiento** | Etapa 3C, bloque de Traefik/escalado. |
| **Causa raíz** | `RC-022` |
| **Acción** | Documentar en ADR la dependencia del healthcheck Docker; evaluar `loadbalancer.healthcheck` y `serversTransport.forwardingTimeouts` si la corrida final muestra 502/503 del borde. |
| **Estado** | `[ACEPTADO POR DISEÑO]` (2026-10-20): documentado en ADR D19. |
| **Restricciones** | Sin corrida de carga no se cuantifica. |

### FIND-036

| Campo | Valor |
|---|---|
| **ID** | `FIND-036` |
| **Título** | Dashboard de Traefik expuesto en el entrypoint público sin autenticación |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | seguridad |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `traefik/traefik.yml:20-21` (`api.dashboard: true`); `traefik/dynamic/config.yml:5-9` (router `traefik.pdf-extractext.localhost` en entrypoint `https`, sin middleware) |
| **Descripción** | Cualquier proceso local puede consultar el mapa completo de routers/servidores del stack vía el dashboard en :443; no hay `basicAuth`, IP allowlist ni restricción al entrypoint `internal`. |
| **Evidencia** | Configuración completa de Traefik leída; grep de middlewares en `dynamic/config.yml` → ninguno. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Fuga de topología/rutas del sistema en un entorno que además monta el docker.sock (`:ro`). |
| **Descubrimiento** | Etapa 3C, bloque de seguridad de infraestructura. |
| **Causa raíz** | `RC-023` |
| **Acción** | `basicAuth` sobre el router del dashboard o moverlo al entrypoint interno. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): dashboard al entrypoint `internal` (`:443` exclusivo de la API). |
| **Restricciones** | Decisión del equipo (usabilidad del dashboard en dev). |

### FIND-037

| Campo | Valor |
|---|---|
| **ID** | `FIND-037` |
| **Título** | Acoplamiento duro al nombre del proyecto (`pdf-extractext`) en Traefik y smoke |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | configuración / Twelve-Factor |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `traefik/traefik.yml:28` (`network: pdf-extractext_services`); `docker-compose.yml:1` (`name: pdf-extractext`); `scripts/smoke.sh:14` (`NET_SERVICES`) y `:45,59,178,187` (contenedor `pdf-extractext-mongodb-1`) |
| **Descripción** | Cambiar `name:` o usar `COMPOSE_PROJECT_NAME` rompe el descubrimiento de Traefik (`providers.docker.network`) y los checks del smoke, que asuman el nombre exacto. |
| **Evidencia** | Valores hardcodeados en los 3 archivos, sin parametrización por env. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Fricción operativa al clonar/renombrar el proyecto; fallos espurios de smoke/Traefik. |
| **Descubrimiento** | Etapa 3C, revisión de Twelve-Factor. |
| **Causa raíz** | `RC-024` |
| **Acción** | Derivar red/contenedores vía `docker compose ps -q` o documentar el acoplamiento en el README. |
| **Estado** | `[ACEPTADO POR DISEÑO]` (2026-10-20): documentado en ADR D17. |
| **Restricciones** | — |

### FIND-038

| Campo | Valor |
|---|---|
| **ID** | `FIND-038` |
| **Título** | Healthcheck de MongoDB sin default de interpolación (inconsistente con las env del servicio) |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | configuración |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `docker-compose.yml:146` (`-u ${MONGO_INITDB_ROOT_USERNAME}` sin `:-dev`) vs `:134-135` (env del servicio con `${…:-dev}`) |
| **Descripción** | Un arranque sin `.env` (fuera de `make check`) deja credenciales vacías en el healthcheck: Mongo nunca pasa a healthy y Persistence no arranca, aunque el propio Mongo sí arrancaría con dev/dev. |
| **Evidencia** | Comparación de líneas del compose; `docker compose config` con `.env` presente sí resuelve dev/dev (verificado). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Arranque frágil fuera del flujo Make; confusión entre "falta .env" y "Mongo roto". |
| **Descubrimiento** | Etapa 3C, revisión de variables de entorno. |
| **Causa raíz** | `RC-024` |
| **Acción** | Alinear a `${MONGO_INITDB_ROOT_USERNAME:-dev}` (o exigir env obligatoria en ambos lugares). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): healthcheck de Mongo con `${…:-dev}`. |
| **Restricciones** | — |

### FIND-039

| Campo | Valor |
|---|---|
| **ID** | `FIND-039` |
| **Título** | `smoke.sh` asume 1 réplica de Extraction y nombres de contenedor fijos |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | testing / configuración |
| **Severidad** | Media (el smoke no valida el stack escalado, que es la configuración exigida del TP) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `scripts/smoke.sh:27-32` (check 1 compara la cadena exacta `api extraction mongodb persistence traefik`); `:45,59,178,187` (nombre `pdf-extractext-mongodb-1`) |
| **Descripción** | Con `EXTRACTION_REPLICAS>1` el check 1 falla (aparece `extraction` N veces); los checks 3/12/13 dependen del nombre por defecto del contenedor de Mongo. `record-run.sh`, en cambio, sí cuenta réplicas dinámicamente. |
| **Evidencia** | `smoke.sh:27-32` (`ps --status running --format '{{.Service}}'` comparado con lista exacta) vs `record-run.sh:70` (`replicas()` con `grep -c`). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | No se puede certificar con smoke un stack de 3–5 réplicas antes de las pruebas de carga. |
| **Descubrimiento** | Etapa 3C, alineación de scripts vs escalado. |
| **Causa raíz** | `RC-025` |
| **Acción** | Comparar servicios únicos (`sort -u`) y resolver Mongo vía `docker compose ps -q mongodb`. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): smoke soporta 1-5 réplicas y Mongo dinámico. |
| **Restricciones** | Corrección pospuesta a la fase de correcciones. |

### FIND-040

| Campo | Valor |
|---|---|
| **ID** | `FIND-040` |
| **Título** | OpenAPI incompleto: faltan `/extract` y el CRUD `/documents`; default de tamaño obsoleto |
| **Etapa** | Etapa 3C (2026-10-19) — pendiente `R-06` |
| **Categoría** | documentación / contrato |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `docs/openapi.yaml:19-33` (solo `GET /`) y `:34-193` (solo `POST /upload-pdf`); rutas reales `internal/api/extract.go:19`, `documents.go:21-24`, `root.go:13`, `upload_pdf.go:25` |
| **Descripción** | 5 de 7 endpoints registrados no están documentados (`POST /extract`, `GET/GET{id}/PATCH/DELETE /documents`); el schema `ExtractionResponse` (`openapi.yaml:207-222`) queda huérfano y `:44` declara "20 MB por defecto" cuando el real es 16 (`internal/core/config.go:48`). |
| **Evidencia** | `grep '^  /'` sobre el YAML → solo `/` y `/upload-pdf`; los 422/503/504 sí están bien especificados en `/upload-pdf` (`:127-193`). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | La documentación no cubre el contrato público completo del TP. |
| **Descubrimiento** | Etapa 3C, verificación de `R-06`/`FIND-004`. |
| **Causa raíz** | `RC-026` |
| **Acción** | Completar `/extract` y `/documents` (reusando `ProblemResponse`), corregir default a 16 MB. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): OpenAPI 1.2.0 con `/extract`, CRUD y default 16 MB. |
| **Restricciones** | Documentación, sin cambio de comportamiento. |

### FIND-041

| Campo | Valor |
|---|---|
| **ID** | `FIND-041` |
| **Título** | README/env/compose locales de API promueven `EXTRACTION_URL` directo (sin Traefik) y default 20 MB |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | documentación / configuración |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `.env.example:13` (`EXTRACTION_URL=http://extraction:8001`), `README.md:39` (mismo ejemplo), `docker-compose.yml:10` (`MAX_FILE_SIZE_MB:-20`) y `:13-18` (labels heredadas: red `cabras-net`, entrypoint `web`, `PathPrefix(/)`) |
| **Descripción** | Contradice D3/DEC-03 (routing API→Extraction vía `http://traefik:8090` con Host `extraction.pdf-extractext.localhost`); el default 20 MB contradice el 16 acordado (`ASK-012`). El compose local de API queda además inutilizable sin la red externa `cabras-net`. |
| **Evidencia** | Infrastructure `docker-compose.yml:37` fija `http://traefik:8090`; README/env de API citan el acceso directo. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Quien levante la API con esos archivos omite Traefik y mide un camino distinto al de producción. |
| **Descubrimiento** | Etapa 3C, revisión Twelve-Factor/documentación cruzada. |
| **Causa raíz** | `RC-026` |
| **Acción** | Cambiar ejemplos a `http://traefik:8090` (o marcar `http://extraction:8001` como "solo smoke sin Traefik") y alinear el default a 16. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): README/env/compose de API a `traefik:8090` y 16 MB. |
| **Restricciones** | — |

### FIND-042

| Campo | Valor |
|---|---|
| **ID** | `FIND-042` |
| **Título** | IDs de issues/auditoría en Dockerfiles, Makefiles y scripts; targets duplicados en el Makefile del extractor |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | clean code / documentación |
| **Severidad** | Baja |
| **Repositorio** | los 4 repos (infraestructura y Dockerfiles) |
| **Ubicación** | `api/Dockerfile:2-6` (bloque "Issue #12", 5 líneas); `extractor/Dockerfile:2` ("Issue #7"); `extractor/docker-compose.yml:1`; `extractor/Makefile:15` ("Issue #8/#9") con `load-test`/`stress-test` definidos dos veces (`:16-26` vs `:37-51`, las primeras definiciones son muertas); `extractor/tests/load/profile.sh:2`; `extractor/tests/test_container_config.py:1`; `infra/tests/load/run_k6.sh:49` (`FIND-003` dentro del string de `--load`) |
| **Descripción** | Referencias a IDs que envejecen mal en código fuente, comentarios de varias líneas y duplicación de targets en Make (make usa la última definición). |
| **Evidencia** | Grep `Issue #|FIND-0` sobre Dockerfiles/Makefiles/scripts; lectura del Makefile del extractor. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Ruido y deuda de mantenibilidad; confusión sobre cuál target de carga es el activo. |
| **Descubrimiento** | Etapa 3C, auditoría de Clean Code de infraestructura/scripts. |
| **Causa raíz** | `RC-027` |
| **Acción** | Eliminar IDs y la primera definición duplicada; comentarios de 1 línea solo donde aportan el "porqué". |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): IDs y targets duplicados eliminados. |
| **Restricciones** | Corrección en la fase aprobada; no se modificó nada ahora. |

### FIND-043

| Campo | Valor |
|---|---|
| **ID** | `FIND-043` |
| **Título** | `.dockerignore` de API y Persistence no cubren artefactos de repo (contexto de build sucio) |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | configuración / build |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-api`, `pdf-extractext-persistence` |
| **Ubicación** | `api/.dockerignore` (sin `.github/`, `docs/`, `docker-compose.yml`, `Dockerfile`, `.golangci.yml`, `Makefile`); `persistence/.dockerignore` (sin `tests/`, `docker-compose.yml`, `Makefile`); el extractor sí los cubre todos (`extractor/.dockerignore:1-16`) |
| **Descripción** | `.git` y `.env` están excluidos en los tres (correcto); el resto solo ensucia el contexto de build (multi-stage: no llegan a la imagen final). |
| **Evidencia** | Lectura de los 3 `.dockerignore` y de los Dockerfiles (etapa runtime copia solo binarios/venv). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Contexto de build más grande y menos reproducible; sin fuga a la imagen final. |
| **Descubrimiento** | Etapa 3C, bloque de Dockerfiles. |
| **Causa raíz** | `RC-028` |
| **Acción** | Completar exclusiones al estándar del extractor. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): `.dockerignore` de API y Persistence completados. |
| **Restricciones** | — |

### FIND-044

| Campo | Valor |
|---|---|
| **ID** | `FIND-044` |
| **Título** | Endurecimiento de imágenes inconsistente: solo API pinnea bases por digest |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | seguridad / reproducibilidad |
| **Severidad** | Baja |
| **Repositorio** | los 3 servicios |
| **Ubicación** | `api/Dockerfile:10,28` (digests pinneados); `persistence/Dockerfile:4,19` (`golang:1.27-alpine`, `distroless/static-debian12:nonroot` sin digest); `extractor/Dockerfile:5,21` (`python:3.12-slim` mutable; `:8` uv por versión) |
| **Descripción** | Las imágenes base de Persistence y Extraction pueden cambiar bajo el mismo tag, rompiendo la reproducibilidad y la pinza de seguridad que sí tiene la API. |
| **Evidencia** | Lectura directa de los 3 Dockerfiles. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Builds no bit-a-bit reproducibles; superficie de supply-chain. |
| **Descubrimiento** | Etapa 3C, bloque de Dockerfiles. |
| **Causa raíz** | `RC-028` |
| **Acción** | Pinneares digests también en Persistence/Extraction (o documentar la excepción). |
| **Estado** | `[ACEPTADO POR DISEÑO]` (2026-10-20): documentado en ADR D18 (riesgo bajo). |
| **Restricciones** | — |

### FIND-045

| Campo | Valor |
|---|---|
| **ID** | `FIND-045` |
| **Título** | Runtime degradado: el Traefik del proyecto está sin redes ni puertos y otro Traefik ajeno retiene 80/443 |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | operabilidad / entorno |
| **Severidad** | **Alta** (bloquea la Etapa 4) |
| **Repositorio** | `pdf-extractext-infrastructure` (entorno del host) |
| **Ubicación** | `docker inspect pdf-extractext-traefik-1` (2026-10-19): `NetworkSettings.Networks {}`, `Ports {}`, arrancado 17:45Z; `docker ps`: contenedor `traefik` de otro proyecto (imagen v3.5, config en `~/dockers/traefik`) publica `0.0.0.0:80/443`; `docker network inspect pdf-extractext_services` → solo api/extraction/persistence |
| **Descripción** | La configuración declarada (compose + `traefik.yml`) es correcta, pero el estado del host no la refleja: el Traefik del proyecto está desprendido de la red `services` y sin bind de puertos; el entrypoint público no enruta y `http://traefik:8090` no es alcanzable desde la API. |
| **Evidencia** | `curl -sk https://pdf-extractext.localhost/` → **404** (2026-10-19 23:01Z, servido por el Traefik ajeno); API solo registra healthchecks internos en las últimas 6 h (sin tráfico E2E); sin ejecución de corrección (restricción 6). |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | Todo el flujo público (smoke, k6, Vegeta, `/extract` E2E) falla hasta restaurar el stack; las verificaciones de runtime de Etapas 2/3A siguen válidas para el estado del 2026-10-18, no para el actual. |
| **Descubrimiento** | Etapa 3C, inspección de solo lectura del stack activo. |
| **Causa raíz** | `RC-029` |
| **Acción** | Restaurar con `docker compose up -d` en Infrastructure (requiere autorización) y resolver el conflicto del Traefik externo sobre 80/443 (`ASK-017`). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-20): stack restaurado y verificado E2E (smoke 15/15). |
| **Restricciones** | No se reinició ni reconectó ningún contenedor (restricción 6). |

### FIND-046

| Campo | Valor |
|---|---|
| **ID** | `FIND-046` |
| **Título** | `mock_api.py` no reproduce el contrato real (page_count 0, errores legacy, path duro) |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | testing |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/mock_api.py:21` (`PAGES` todos 0, nunca se llenan), `:26` (`/tmp/opencode/mock-hits.json` hardcodeado), `:57,62,69` (errores `{"error":…}`, no RFC 9457) vs `spike_tests.js:42` (exige `page_count > 0`) |
| **Descripción** | El mock de ensayo (`RECORD=0`) haría fallar el check de contrato de k6 (`page_count`) y no valida el formato de error `problem+json` que sí emite el API real. |
| **Evidencia** | Lectura de ambos archivos. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | El ensayo con mock no es representativo del contrato; métricas del mock no comparables. |
| **Descubrimiento** | Etapa 3C, revisión de scripts de carga. |
| **Causa raíz** | `RC-027` |
| **Acción** | Corregir `page_count`, errores `problem+json` y path de salida al retocar la suite de carga (etapa final). |
| **Estado** | Abierto (diferido con `FIND-003`/`FIND-007`) |
| **Restricciones** | No se ejecutó el mock (escribe en `/tmp`). |

### FIND-047

| Campo | Valor |
|---|---|
| **ID** | `FIND-047` |
| **Título** | Riesgo residual de capacidad en API: 100 VUs × ~16 MB en RAM contra un tope de 512 MiB |
| **Etapa** | Etapa 3C (2026-10-19) |
| **Categoría** | rendimiento / capacidad |
| **Severidad** | Media (solo se manifiesta con el spike de 100 VUs) |
| **Repositorio** | `pdf-extractext-api` (+ Infrastructure) |
| **Ubicación** | `docker-compose.yml:39,44` (`MAX_FILE_SIZE_MB=16`, `memory: 512M`); `cmd/api/main.go:25` (`BodyLimit`); sin límite de concurrencia en la API (`FIND-023`/`ASK-010`) |
| **Descripción** | `FIND-030` bajó el límite de 50→16 MB, pero fasthttp sigue bufferizando el body completo: el techo teórico son ~16–32 requests concurrentes de 16 MB dentro de 512 MiB, y el único control de admisión sigue siendo el 503 de Extraction (1–5 slots). |
| **Evidencia** | Análisis de fasthttp@v1.51.0 (`FIND-030`); límites efectivos verificados por `docker inspect` (mem=536870912, cpu=1e9). Sin corrida de carga → el OOM es `[HIPÓTESIS]`. |
| **Taxonomía** | `[HIPÓTESIS]` + `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo el spike de 100 VUs la API puede recibir OOMKill antes que Extraction, devolviendo 502 masivos. |
| **Descubrimiento** | Etapa 3C, ecuación de capacidad post-3A/3B. |
| **Causa raíz** | `RC-016` |
| **Acción** | Medir en Etapa 4 con k6 100 VUs (`docker stats`/OOMKilled); si hay OOM, decidir entre subir la memoria de la API o limitar concurrencia en el borde (reabre `ASK-010`). |
| **Estado** | Abierto — `[DECISIÓN-PENDIENTE]` condicionada a la medición |
| **Restricciones** | No se ejecutó carga (restricción del equipo). |

### FIND-048

| Campo | Valor |
|---|---|
| **ID** | `FIND-048` |
| **Título** | Los targets de Vegeta están en formato `http` con body embebido, que Vegeta v12 rechaza → el ataque envía 0 peticiones |
| **Etapa** | Etapa 4 (2026-10-20) |
| **Categoría** | testing / validez del benchmark |
| **Severidad** | **Alta** (invalida por completo la corrida de carga abierta del TP) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/vegeta/run_vegeta.sh:53-59` (target en formato `http`) y `:64` (`vegeta attack` sin `-format`); formato objetivo en `lib/targets.go` de Vegeta (`NewHTTPTargeter` exige la primera línea con método en mayúsculas y body solo vía `@ruta`) |
| **Descripción** | El script emite cada target como `POST <url>` + cabeceras + línea en blanco + **body multipart embebido**. Vegeta ≥ 12.8 lee targets en modo JSON (`{method,url,header,body(base64)}`); en modo `http` la primera línea no vacía debe empezar con un método HTTP y el body solo se admite con `@/ruta`. La línea `--pdf-extractext-vegeta-boundary` no encaja → el ataque aborta. |
| **Evidencia** | Reproducción del comando literal del repo contra un stub local: `vegeta attack -targets=work/targets.txt …` → `bad target: --pdf-extractext-vegeta-boundary`, exit 1, **0 peticiones**. Reproducción equivalente en `-format=json` (mismo multipart, body base64) → **6/6 peticiones, 200 OK**, multipart válido, `Content-Length` == bytes reales. Las mismas líneas del script (`:45-49`) generan el multipart correcto. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | `make load-vegeta` y cualquier corrida de carga abierta fallan antes de medir; no hay métricas de Vegeta válidas ni comparables con el TP. |
| **Descubrimiento** | Etapa 4, validación acotada de sintaxis de targets con `vegeta` v12.13 contra stub local. |
| **Causa raíz** | `RC-030` |
| **Acción** | Reescribir los targets en `-format=json` (body base64) **o** pasar el body con `@/ruta` al fichero multipart; verificar con una corrida corta contra el stack. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-21): reescrito a `-format=json` con body base64 (`--rawfile`); validado contra `tests/load/mock_api.py` (150 reqs a 50/s y 30 a 10/s; `bad:0`, `no_file:0`; multipart aceptado por el mock que verifica SHA256). La corrida real queda pendiente de validación. |
| **Restricciones** | Corrida real pendiente de ejecución. |

### FIND-049

| Campo | Valor |
|---|---|
| **ID** | `FIND-049` |
| **Título** | `run_k6.sh` usa `--summary-export` retirado en k6 v2.x → resumen no generado y métricas a 0 |
| **Etapa** | Etapa 4 (2026-10-20) |
| **Categoría** | testing / instrumentación |
| **Severidad** | Media (la corrida ocurre, pero las métricas capturadas son nulas) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/run_k6.sh:21` (`--summary-export="$SUMMARY"`), `:23-38` (parseo del JSON); k6 instalado = **v2.3.0** |
| **Descripción** | k6 v2.3.0 ya no documenta `--summary-export` (sustituido por `handleSummary()`), por lo que `$SUMMARY` no se crea y `stat_ms`/throughput/success devuelven 0 silenciosamente. |
| **Evidencia** | `k6 run --help` en v2.3.0 no lista `--summary-export` (sí `--summary-mode`/`--new-machine-readable-summary`); el wrapper `|| 0` oculta la ausencia de `$SUMMARY`. `k6 inspect tests/load/spike_tests.js` confirma que el escenario se carga pero con `target: 1` (ver `FIND-003`). |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Aunque el spike corra, p50/p90/p95/throughput/%éxito registrados son 0; las corridas de k6 no aportan métricas al informe. |
| **Descubrimiento** | Etapa 4, `k6 inspect` + `k6 run --help`. |
| **Causa raíz** | `RC-031` |
| **Acción** | Implementar `handleSummary()` en `spike_tests.js` (escribe el JSON con `--out` o en `teardown`) y ajustar el parseo del wrapper; comprobar la versión de k6 con fail-fast. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-21): `handleSummary()` escribe el JSON en `K6_SUMMARY_PATH`; `run_k6.sh` parsea `.metrics.*.values.*` y muestra p50/p90/p95/p99. Validado contra `tests/load/mock_api.py` (8 reqs, `extract_ok` 100 %, métricas no-cero; claves `med`/`p(90)`/`p(95)`/`p(99)` confirmadas). La corrida real queda pendiente de validación. |
| **Restricciones** | Corrida real pendiente de ejecución. |

### FIND-050

| Campo | Valor |
|---|---|
| **ID** | `FIND-050` |
| **Título** | Corpus de carga con disparidad de coste ×28 y sin caso de imagen escaneada |
| **Etapa** | Etapa 4 (2026-10-20) |
| **Categoría** | testing / validez del benchmark |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/pdfs/` (4 PDFs); `tests/load/spike_tests.js:27` (rotación aleatoria), `tests/load/vegeta/run_vegeta.sh:42` (round-robin) |
| **Descripción** | El PDF más caro (Kanban, 8,5 MB/90p/91 imágenes) cuesta ~28× el más barato (Scrum Guide, 319 KB/16p/0 imágenes). La rotación mezcla ambos en el mismo conjunto de percentiles, y ningún PDF es escaneado (todos texto nativo, ninguno cifrado), así que no se ejercita ese camino del extractor. |
| **Evidencia** | `pdfinfo`/`pdfimages -list`/`pdftotext` (2026-10-20): 16/90/42/62 páginas; 0/91/21/40 imágenes; 35.345/125.211/59.089/91.228 caracteres. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | Los percentiles no representan un perfil homogéneo; la varianza del corpus contamina la comparación entre corridas y con la referencia del TP. |
| **Descubrimiento** | Etapa 4, caracterización del corpus. |
| **Causa raíz** | `RC-006` / `FIND-011` |
| **Acción** | Documentar el corpus efectivo (3 hashes) en cada corrida y/o añadir un PDF escaneado y un peso intermedio; o separar métricas por PDF. |
| **Estado** | Abierto — `[RECOMENDACIÓN]` |
| **Restricciones** | Solo lectura del corpus; no se alteraron datos de prueba (restricción 3). |

### FIND-051

| Campo | Valor |
|---|---|
| **ID** | `FIND-051` |
| **Título** | Las suites de carga no capturan instrumentación de infraestructura (CPU/mem/OOM/reinicios/réplicas) |
| **Etapa** | Etapa 4 (2026-10-20) |
| **Categoría** | testing / observabilidad |
| **Severidad** | Media (limita la atribución de causas, no invalida el resultado) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/run_k6.sh`, `tests/load/vegeta/run_vegeta.sh`, `scripts/record-run.sh:78-119` (solo extrae límites estáticos, no uso en vivo) |
| **Descripción** | Los scripts solo persisten la salida del cliente. No hay recolección de `docker stats` (CPU/mem), `OOMKilled`/`RestartCount`, estado de healthcheck durante la carga ni distribución de peticiones entre réplicas de Extraction. |
| **Evidencia** | Lectura de los tres scripts; `record-run.sh` consulta `docker inspect` para límites/versiones, nunca uso en vivo durante el ataque. |
| **Taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | `HYP-07` (RSS/OOM de Extraction), `FIND-047` (OOM de API), `HYP-08` (healthcheck) y `FIND-035` (SPOF Traefik) no se pueden validar con lo que capturan los scripts actuales. |
| **Descubrimiento** | Etapa 4, revisión de instrumentación. |
| **Causa raíz** | — (limitación de diseño de la suite) |
| **Acción** | Añadir al protocolo de ejecución (§6.6 de `audit-benchmark.md`) la captura paralela de `docker stats --no-stream` y `docker inspect` de estado, y adjuntarla al registro de la corrida. |
| **Estado** | Abierto — `[RECOMENDACIÓN]` |
| **Restricciones** | No se ejecutaron cargas (restricción 6). |

### FIND-053

| Campo | Valor |
|---|---|
| **ID** | `FIND-053` |
| **Título** | `run_k6.sh` declaraba `TARGET_URL` pero nunca la pasaba a k6: el spike siempre atacaba el dominio por defecto |
| **Etapa** | Etapa 4 (2026-10-21) |
| **Categoría** | testing / configuración |
| **Severidad** | Media (impedía dirigir el ensayo a un mock/override; las corridas reales usaban el default) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/run_k6.sh` (uso de `TARGET_URL`) vs `tests/load/spike_tests.js:21` (`BASE_URL`) |
| **Descripción** | El runner aceptaba `TARGET_URL` pero solo lo usaba para la descripción del registro; k6 construye `${BASE_URL}/extract` y `BASE_URL` no se exportaba, por lo que cualquier `TARGET_URL` era ignorado silenciosamente (el ensayo con `RECORD=0 TARGET_URL=<mock>` golpeaba `https://pdf-extractext.localhost`). Detectado al validar contra el mock. |
| **Evidencia** | Antes: `RECORD=0 TARGET_URL=http://127.0.0.1:8642/extract bash run_k6.sh` → k6 intentaba `https://pdf-extractext.localhost/extract` (`connection refused`), `extract_ok` 0 %. Después: se deriva `BASE_URL="${BASE_URL:-${TARGET_URL%/extract}}"` y se exporta → 8 reqs al mock, `extract_ok` 100 %, `bad:0`. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` (mock oficial) |
| **Impacto** | Corregido: `TARGET_URL` es ahora la única perilla de destino en k6. |
| **Descubrimiento** | Validación contra `tests/load/mock_api.py` (2026-10-21). |
| **Causa raíz** | `RC-033` |
| **Acción** | Hecho: derivar y exportar `BASE_URL` desde `TARGET_URL`. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-21) |
| **Restricciones** | — |

### FIND-054

| Campo | Valor |
|---|---|
| **ID** | `FIND-054` |
| **Título** | `mock_api.py` devolvía `page_count: 0`, por lo que el check de k6 (`page_count > 0`) nunca podía pasar contra el mock |
| **Etapa** | Etapa 4 (2026-10-21) |
| **Categoría** | testing / validez de la validación |
| **Severidad** | Baja (solo afecta al ensayo con mock, no a la corrida real) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/mock_api.py:21` (`PAGES = {n: 0 …}`), respuesta en `:72`; check en `spike_tests.js:44-52` |
| **Descripción** | El mock (creado "para ensayar k6/Vegeta sin stack") respondía `page_count: 0`, de modo que el check `JSON con content y page_count` de k6 fallaba siempre aunque el multipart fuera correcto; `http_req_failed` 0 % pero `extract_ok` 0 %, un falso negativo que impedía validar el camino de éxito. |
| **Evidencia** | Antes: 8 reqs al mock → `extract_ok` 0 %. Después de fijar los conteos reales (16/90/42/62, coherentes con la caracterización del corpus): `extract_ok` 100 %, `bad:0`, `no_file:0`. |
| **Taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | Corregido: el ensayo con mock ahora ejercita el camino de éxito completo. |
| **Descubrimiento** | Validación contra `tests/load/mock_api.py` (2026-10-21). |
| **Causa raíz** | `RC-034` |
| **Acción** | Hecho: `PAGES` con los conteos reales de cada PDF. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (2026-10-21) |
| **Restricciones** | Solo afecta a la herramienta de ensayo; no toca API/Extraction/Persistence. |
