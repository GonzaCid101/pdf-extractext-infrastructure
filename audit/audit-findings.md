# Audit Findings — PDF Extractext

Registro de hallazgos de la auditoría. Cada hallazgo usa la plantilla de 16 campos.
Taxonomía obligatoria: `[VERIFICADO-CÓDIGO]`, `[VERIFICADO-PRUEBA]`, `[DOCUMENTADO-NO-VERIFICADO]`, `[HIPÓTESIS]`, `[RECOMENDACIÓN]`, `[DECISIÓN-PENDIENTE]`.

## Plantilla de hallazgo (16 campos)

1. **ID** (`FIND-XXX`)
2. **Título**
3. **Etapa de detección**
4. **Categoría** (contrato / arquitectura / configuración / documentación / rendimiento / testing / seguridad)
5. **Severidad** (Alta / Media / Baja)
6. **Repositorio**
7. **Ubicación** (`ruta:archivo:línea`)
8. **Descripción**
9. **Evidencia**
10. **Etiqueta de taxonomía**
11. **Impacto**
12. **Condiciones de descubrimiento**
13. **Causa raíz asociada** (`RC-XX` o "sin asignar")
14. **Acción recomendada** (solo recomendación; la auditoría NO corrige)
15. **Estado** (Abierto / En análisis / Cerrado)
16. **Restricciones / notas**

---

## Causas Raíz (`RC-XX`)

Se derivan de los hallazgos a medida que avanzan las etapas. Todavía sin asignar formalmente:

| ID | Causa raíz propuesta | Hallazgos asociados | Estado | Etiqueta |
|---|---|---|---|---|
| `RC-001` | El conjunto oficial de PDFs nunca se commiteó (excluido por `.gitignore`) y el comentario del `.gitignore`/README quedó desalineado con el estado real del repo. | `FIND-001`, `FIND-002` | **Resuelta** (2026-10-18): PDFs versionados y textos alineados | `[VERIFICADO-CÓDIGO]` |
| `RC-002` | Los README de los tres servicios no se actualizaron tras la implementación de funcionalidad posterior al bootstrap (issues de extracción, persistencia y orquestación). | `FIND-004` | **Resuelta** (2026-10-18): READMEs actualizados | `[HIPÓTESIS]` |
| `RC-003` | Coexisten dos suites de carga (una del repo Extractor y una de Infrastructure) sin definir cuál es la canónica del TP. | `FIND-003` | Propuesta | `[HIPÓTESIS]` |
| `RC-004` | El informe técnico se redactó con datos de ejemplo/simulados en lugar de corridas reales y no se reemplazaron al obtener mediciones. | `FIND-008` | Propuesta | `[HIPÓTESIS]` |
| `RC-005` | Los documentos de infraestructura (ADR, README, `.env.example`) evolucionaron sin una revisión de consistencia cruzada tras cada cambio de implementación. | `FIND-009`, `FIND-010` | Propuesta | `[HIPÓTESIS]` |
| `RC-006` | El conjunto de PDFs de carga se armó copiando archivos sin verificar su procedencia/hash, dejando un duplicado del PDF pesado del extractor. | `FIND-011` | Propuesta | `[HIPÓTESIS]` |
| `RC-007` | El cliente HTTP del API colapsa cualquier status de upstream en un error genérico (502/500), sin distinguir saturación (503), error de cliente (400/422) o fallo real. | `FIND-012`, `FIND-013` | `[RESUELTA - IMPLEMENTADA]` (commits extractor `627aecf`, persistence `2af0e62`, API `fb3d7c3`) | `[VERIFICADO-PRUEBA]` |
| `RC-008` | El API genera request-id localmente pero `persistence_client.go` no lo envía como header: la correlación distribuida se rompe en el salto API→Persistence. | `FIND-014` | `[RESUELTA - IMPLEMENTADA]` (commit API `fb3d7c3`) | `[VERIFICADO-PRUEBA]` |
| `RC-009` | El catálogo de códigos del extractor no define un code de saturación: el 503 reutiliza `INTERNAL_ERROR`. | `FIND-015` | `[RESUELTA - IMPLEMENTADA]` (commit extractor `627aecf`) | `[VERIFICADO-PRUEBA]` |

---

## Hallazgos (`FIND-XXX`)

### FIND-001

| Campo | Valor |
|---|---|
| **ID** | `FIND-001` |
| **Título** | Los 4 PDFs oficiales no estaban versionados: presentes en disco local pero excluidos por `.gitignore` |
| **Etapa de detección** | Etapa 1 (re-verificado 2026-10-18) |
| **Categoría** | testing / configuración |
| **Severidad** | Alta (impedía reproducir la línea base desde un clon limpio) |
| **Repositorio** | Workspace `Microservicios/` (los 4 repos) |
| **Ubicación** | `pdf-extractext-infrastructure/tests/load/pdfs/` (4 PDFs) y `.gitignore` (regla `tests/load/pdfs/*.pdf`, ya eliminada). La ruta de la cátedra `tests/stress/pdfs` sigue sin existir en ningún repo. |
| **Descripción** | Los 4 PDFs oficiales (`2020-Scrum-Guide-Spanish-Latin-South-American.pdf`, `Essential-Kanban-Condensed-Spanish.pdf`, `Filosofia Lean.pdf`, `scrum_manager_historias_usuario.pdf`) estaban presentes en `tests/load/pdfs/` pero **excluidos por `.gitignore`**, por lo que un clon limpio no los tenía y las corridas no eran reproducibles. **Resolución (2026-10-18, revisada):** el equipo decidió **versionarlos**. Se quitó la regla de `.gitignore` y los 4 PDFs se agregan al repo. La ruta del enunciado `tests/stress/pdfs` sigue sin existir (se usa `tests/load/pdfs`). |
| **Evidencia** | - Estado previo: `git ls-files tests/load/pdfs` → solo `generate_fixtures.sh`; `git status --ignored` → los 4 `.pdf` como `!!`. <br> - Estado actual: `.gitignore` sin la regla `tests/load/pdfs/*.pdf`; los 4 `.pdf` agregados al índice. <br> - `find … -type d -name stress` → sin resultados. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Resuelto: un clon limpio contiene el conjunto de carga completo. |
| **Condiciones de descubrimiento** | Re-verificación del filesystem y de `git ls-files`/`git status --ignored` (2026-10-18). |
| **Causa raíz asociada** | `RC-001` |
| **Acción recomendada** | Hecho: `.gitignore` actualizado y PDFs versionados. Queda por resolver la calidad del dato (`FIND-011`: uno de los PDFs está duplicado) y confirmar si `tests/stress/pdfs` (enunciado) designa el mismo conjunto (`ASK-002`). |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-18): PDFs versionados en `tests/load/pdfs/`. |
| **Restricciones / notas** | No se regeneran ni se sustituyen por fixtures artificiales. `FIND-011` sigue abierto (contenido duplicado). |

---

### FIND-002

| Campo | Valor |
|---|---|
| **ID** | `FIND-002` |
| **Título** | Contradicción documental: el `.gitignore` y el README afirmaban que los PDFs oficiales estaban versionados, pero el propio `.gitignore` los excluía |
| **Etapa de detección** | Etapa 1 (resuelto 2026-10-18) |
| **Categoría** | documentación / configuración |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `.gitignore` (regla `tests/load/pdfs/*.pdf`, ya eliminada) y `README.md` (sección de pruebas de carga) |
| **Descripción** | El comentario del `.gitignore` decía que los PDFs "ya están copiados en el repositorio" mientras la línea siguiente los ignoraba (`tests/load/pdfs/*.pdf`); el README afirmaba que el conjunto oficial era "Sin `generate_fixtures.sh`", dando a entender que estaba versionado. **Resolución (2026-10-18, revisada):** se eliminó la regla de `.gitignore` y el README declara que los PDFs **sí se versionan**; el registro de corridas (`docs/test-runs/`) sigue siendo local. |
| **Evidencia** | - Estado previo: `.gitignore` (regla `tests/load/pdfs/*.pdf`), `README.md` (§Pruebas de carga). <br> - Estado actual: `.gitignore` sin la regla; `README.md` ("PDFs oficiales … SÍ se versionan"). |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo tras la corrección: el clon limpio ya incluye el conjunto de carga. |
| **Condiciones de descubrimiento** | Contraste entre textos documentales y el listado/trackeo real del directorio. |
| **Causa raíz asociada** | `RC-001` |
| **Acción recomendada** | Resuelto por decisión del equipo (2026-10-18): versionar los PDFs y documentarlo. |
| **Restricciones / notas** | Contradicción registrada también como `CON-001`/`CON-002` en `audit-decisions.md`. |

---

### FIND-003

| Campo | Valor |
|---|---|
| **ID** | `FIND-003` |
| **Título** | `make load-k6` ejecuta un spike de 1 VU, no el spike de 100 VUs exigido por el TP; el script de 100 VUs (`k6-spike.js`) no está referenciado por el Makefile |
| **Etapa de detección** | Etapa 1 |
| **Categoría** | rendimiento / configuración |
| **Severidad** | **Alta** (la herramienta de ejecución no produce el perfil del TP) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `Makefile:57-58` → `tests/load/run_k6.sh:21` → `tests/load/spike_tests.js:8-12` (stages `target: 1`); el script de 100 VUs (`k6-spike.js`) fue **eliminado el 2026-10-18** sin haber estado referenciado nunca |
| **Descripción** | El README (`README.md:75, 81-83`) documenta `make load-k6` como "spike: 10s→100 VUs, 20s, 10s→0". En la implementación real, `run_k6.sh` ejecuta `spike_tests.js`, cuyas stages suben a **1 VU** (`{ duration: '20s', target: 1 }`). **Decisión del equipo (2026-10-18):** `spike_tests.js` es el script canónico y `k6-spike.js` (perfil de 100 VUs con fixtures generados) fue **eliminado**; el perfil de 100 VUs se implementará en `spike_tests.js` al final del ciclo (junto con el rate de Vegeta), cuando se corrijan los perfiles de carga. Queda abierto hasta entonces. |
| **Evidencia** | - `Makefile:57-58`: `load-k6: check` → `bash tests/load/run_k6.sh`. <br> - `run_k6.sh:21`: `k6 run --summary-export=… ${K6_ARGS:-} tests/load/spike_tests.js`. <br> - `spike_tests.js:9-11`: stages `target: 1`. <br> - `k6-spike.js` eliminado del repo el 2026-10-18 (git history conserva su perfil). <br> - Grep: `k6-spike.js` no aparece en `Makefile`, `run_k6.sh` ni README. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Ejecutar el benchmark tal como está cableado NO reproduce el escenario del TP (100 VUs); las métricas resultantes no serían comparables con la referencia (P50 1,88s, P90 7,83s, 25,35 req/s). |
| **Condiciones de descubrimiento** | Lectura cruzada Makefile → run_k6.sh → scripts k6, contrastando con el perfil del enunciado. |
| **Causa raíz asociada** | `RC-003` |
| **Acción recomendada** | Resuelta la elección del canónico (`ASK-003`): implementar las stages 100 VUs en `spike_tests.js` al corregir los perfiles de carga. |
| **Estado** | Abierto (perfil pendiente; `k6-spike.js` eliminado 2026-10-18) |
| **Restricciones / notas** | Corrección de perfiles pospuesta por el equipo hasta la etapa final de benchmarks. |

---

### FIND-004

| Campo | Valor |
|---|---|
| **ID** | `FIND-004` |
| **Título** | READMEs de API, Extraction y Persistence desactualizados respecto del código real |
| **Etapa de detección** | Etapa 1 (resuelto 2026-10-18) |
| **Categoría** | documentación |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api`, `pdf-extractext-extractor`, `pdf-extractext-persistence` |
| **Ubicación** | Ver evidencia por servicio |
| **Descripción** | Los tres README describían un estado "bootstrap" que el código ya había superado: <br> **(a) API**: decía que `PERSISTENCE_URL` era "requisito muerto… ningún código la consume" (issue #6), que `/extract` estaba "no registrado aún" y que no había endpoints CRUD. <br> **(b) Extraction**: decía "bootstrap inicial… fase actual: recepción" y que la respuesta era `{filename, size}`. <br> **(c) Persistence**: decía "El CRUD y el repositorio se implementarán en etapas posteriores". **Resolución (2026-10-18):** los tres README se reescribieron/actualizaron al estado real (endpoints, contratos, variables de entorno y estructura). También se corrigió el comentario obsoleto de `pdf-extractext-api/.env.example` (`PERSISTENCE_URL` "aún sin consumo"). |
| **Evidencia** | - API: `cmd/api/main.go:36-40` registra `/extract`, `/upload-pdf` y `/documents`; `internal/services/persistence_client.go` consume `PERSISTENCE_URL`. <br> - Extractor: `extraction.py` devuelve `{filename, extracted_text, checksum, content, page_count}`; `main.py` expone `/health` y `/readyz`. <br> - Persistence: `internal/api/router.go:26-37` registra CRUD + probes. <br> - READMEs actualizados en los tres repos. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo tras la corrección: la documentación refleja el contrato real. |
| **Condiciones de descubrimiento** | Comparación de READMEs vs `main.go`, `router.go` y `extraction.py`. |
| **Causa raíz asociada** | `RC-002` |
| **Acción recomendada** | Hecho (2026-10-18). Queda pendiente ampliar `pdf-extractext-api/docs/openapi.yaml` (hoy solo documenta `/` y `/upload-pdf`). |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-18): READMEs de API, Extraction y Persistence actualizados. |
| **Restricciones / notas** | Cambios de solo documentación; no se tocó comportamiento. |

---

### FIND-005

| Campo | Valor |
|---|---|
| **ID** | `FIND-005` |
| **Título** | No existe conversión a Markdown en ningún servicio: `content` es texto plano de PyMuPDF |
| **Etapa de detección** | Etapa 1 |
| **Categoría** | contrato |
| **Severidad** | Media (potencial brecha funcional vs enunciado) |
| **Repositorio** | `pdf-extractext-extractor` (+ traspaso en `pdf-extractext-api`) |
| **Ubicación** | `pdf-extractext-extractor/src/pdf_extractext_extractor/domain/extractor.py:31-39`, `pdf-extractext-api/internal/api/extract.go:52-56` |
| **Descripción** | El enunciado pide que `content` sea "convertido a Markdown cuando corresponda". La extracción real concatena `page.get_text()` de PyMuPDF (texto plano, sin estructura Markdown) y la API reenvía ese string tal cual en `{content, page_count}`. Búsqueda `markdown|Markdown` en el workspace: 0 resultados. El ADR D14 solo especifica `{"content": "...", "page_count": N}` sin mencionar Markdown. |
| **Evidencia** | `domain/extractor.py:35`: `text = "".join(page.get_text() for page in document)`; grep negativo de `markdown` en los 4 repos. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` (ausencia de conversión) + `[DECISIÓN-PENDIENTE]` (qué espera la cátedra exactamente) |
| **Impacto** | Si la cátedra exige Markdown real (negritas, tablas, encabezados), haría falta un cambio de comportamiento del extractor — que la auditoría solo puede recomendar, no implementar. |
| **Condiciones de descubrimiento** | Lectura del dominio de extracción durante el inventario tecnológico. |
| **Causa raíz asociada** | Sin asignar |
| **Acción recomendada** | Resuelto por decisión del equipo: convertir a Markdown nativo en el extractor (`ASK-005`). |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-17) |
| **Restricciones / notas** | Implementado sin librerías externas de ML/OCR; solo PyMuPDF nativo. |

#### Implementación Realizada y Verificación

**Archivos y rangos modificados**

| Archivo | Cambio |
|---|---|
| `pdf-extractext-extractor/src/pdf_extractext_extractor/domain/extractor.py` | Reescrito: docstring (l.1-13); constantes `_PAGE_SEPARATOR`/`_BULLET_PREFIXES`/`_BOLD_FLAG` (l.28-30); `extract_pdf_data` ahora produce Markdown (l.41-65); `_page_to_markdown` (l.68-121); `_line_properties` (l.124-141); `_base_font_size` (l.144-158); `_heading_level` (l.161-176); `_bullet_content` (l.179-186) |
| `pdf-extractext-extractor/src/pdf_extractext_extractor/extraction.py` | Docstring del contrato aclarado: `extracted_text == content` y ese string es Markdown (l.10-15). **Sin cambios de lógica ni de nombres de campo.** |
| `pdf-extractext-extractor/tests/domain/conftest.py` | Nuevas fixtures `heading_pdf` (l.49), `bullet_list_pdf` (l.61), `two_paragraphs_pdf` (l.73) |
| `pdf-extractext-extractor/tests/domain/test_extractor.py` | Nueva clase `TestMarkdownConversion` con 7 tests (l.128-176) |

**Explicación técnica (algoritmo y recursos)**

- La conversión usa exclusivamente `page.get_text("dict")` de PyMuPDF: no se añaden dependencias de ML/OCR ni se rasteriza a imagen.
- **Base tipográfica** (`_base_font_size`): tamaño de fuente dominante de la página ponderado por cantidad de caracteres; en empate se elige el menor (cuerpo de texto).
- **Encabezados** (`_heading_level`): se clasifica por *ratio* sobre la base → `#` ≥ 1,8×, `##` ≥ 1,5×, `###` ≥ 1,25×; y por **negrita** (bit `1<<4` de `span["flags"]`) cuando la línea es íntegramente negrita, ratio ≥ 1,05× y ≤ 12 palabras → `###`.
- **Listas** (`_bullet_content`): líneas que empiezan con `• - * · ‣ ▪ ◦` se normalizan a `- contenido`.
- **Párrafos**: las líneas se agrupan en un párrafo y se separan por `\n\n`; un salto vertical mayor que el tamaño de fuente base entre líneas se interpreta como nuevo párrafo.
- **Páginas**: se separan con una regla horizontal consistente `\n\n---\n\n` (`_PAGE_SEPARATOR`); las páginas sin texto no generan separador, por lo que un PDF sin texto sigue devolviendo `""` (contrato preservado).
- **Recursos**: complejidad temporal O(n) en cantidad de spans; memoria O(texto). El documento se abre/cierra con context manager (`with pymupdf.open(...)`), garantizando liberación de recursos nativos sin fugas, incluso ante excepciones.
- **Contrato preservado**: el dominio sigue devolviendo `extracted_text`; `extraction.py:113-119` mantiene `extracted_text == content` y `page_count`, y la API sigue leyendo `content` (`extraction_client.go:18`). Nombres de campo 100% compatibles.

**Comandos de prueba y resultado `[VERIFICADO-PRUEBA]`**

```
$ uv run pytest -q   (en pdf-extractext-extractor)
70 passed, 1 xfailed, 2 warnings in 1.66s
```

Los 7 tests nuevos de `TestMarkdownConversion` verifican: encabezado por tamaño, cuerpo no promovido, viñetas como `- item`, ausencia de indentación, separación de párrafos, separación de páginas por `---` y PDF sin texto → `""`.

---

### FIND-007

| Campo | Valor |
|---|---|
| **ID** | `FIND-007` |
| **Título** | `run_vegeta.sh` lanza el ataque a **1 req/s**, no a los 50 req/s documentados por el TP, el README y el ADR D11 |
| **Etapa de detección** | Etapa 1 |
| **Categoría** | rendimiento / configuración |
| **Severidad** | **Alta** (el benchmark ejecutable no implementa el perfil del TP: 30 reqs en 30s vs 1.500 esperados) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `tests/load/vegeta/run_vegeta.sh:21` (`RATE="1/s"`) vs `:71` (`-rate="$RATE"`) y encabezado `:2` ("ataque Vegeta 50 req/s × 30s"); `README.md:76` ("50 req/s × 30s"); `architecture-decisions.md:71` (D11: "Vegeta 50 req/s x 30s") |
| **Descripción** | El script declara `RATE="1/s"` y lo pasa directamente a `vegeta attack -rate="$RATE"`. Con `DURATION=30s`, eso produce ~30 requests, no los 1.500 del perfil del TP (50 req/s × 30s). El propio comentario del script, el README del repo y el ADR D11 documentan 50 req/s: la variable está hardcoded sin default sobreescribible desde el entorno (no es `RATE="${RATE:-1/s}"`). |
| **Evidencia** | - `run_vegeta.sh:21`: `RATE="1/s"`. <br> - `run_vegeta.sh:71-72`: `vegeta attack -rate="$RATE" -duration="$DURATION" …`. <br> - Comentario del script `run_vegeta.sh:2` y README `:76` y D11 documentan 50 req/s. <br> - El resumen impreso (`:70`) usa `${RATE}` tal cual, por lo que una corrida real anunciaría explícitamente "1/s". |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Cualquier corrida con el script actual NO es comparable con la referencia del TP (998 exitosas / 16,65 req/s efectivo / 501 timeouts en 1.500 reqs): con 1 req/s el sistema quedaría subcargado y los latencies/timeouts serían artificialmente bajos. |
| **Condiciones de descubrimiento** | Contraste entre el comentario/README/ADR (50 req/s) y el valor efectivo de `RATE` durante la lectura completa del script para el inventario de benchmarks. |
| **Causa raíz asociada** | `RC-003` |
| **Acción recomendada** | **Decisión del equipo (2026-10-18):** el rate se corrige a `50/s` en la etapa final de benchmarks (`make load-vegeta` hoy corre a 1 req/s). |
| **Estado** | Abierto (corrección diferida) |
| **Restricciones / notas** | Prioridad del equipo: primero el funcionamiento correcto del sistema; las pruebas de carga (k6/Vegeta) quedan para el final junto con `FIND-003`. |

---

### FIND-006

| Campo | Valor |
|---|---|
| **ID** | `FIND-006` |
| **Título** | Deriva documental menor entre ADRs de Infrastructure y la implementación real (healthchecks D8, versiones de Mongo D7) |
| **Etapa de detección** | Etapa 1 |
| **Categoría** | documentación / configuración |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure`, `pdf-extractext-persistence` |
| **Ubicación** | `docs/architecture-decisions.md:53-56` (D8), `docker-compose.yml` (healthchecks reales), `persistence` tests de integración (`mongo:7.0`) |
| **Descripción** | (a) D8 describe healthchecks "CMD-SHELL con `curl -f … /readyz`"; la implementación real usa `["CMD","/healthprobe"]` (binario) para api/persistence y `python3 -c urllib…/readyz` para extraction — coherente con imágenes distroless sin shell, pero el ADR no lo refleja. (b) D7 documenta que Persistence está fijado a `mongo:7.0` en tests de integración mientras el stack usa `mongo:8`; el ADR lo asume como coordinación pendiente ("comunicado al responsable") y sigue sin resolverse en el código. |
| **Evidencia** | `docker-compose.yml:45-48, 93-98, 121-126`; `architecture-decisions.md:48-61`; `persistence/README.md:112` ("testcontainers levanta `mongo:7.0`"). |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` + `[DOCUMENTADO-NO-VERIFICADO]` (no se ejecutaron los tests de integración) |
| **Impacto** | Bajo: no afecta el funcionamiento del stack; sí afecta la trazabilidad de decisiones. |
| **Condiciones de descubrimiento** | Lectura del ADR vs compose vs README de Persistence. |
| **Causa raíz asociada** | `RC-002` (parcial) |
| **Acción recomendada** | Resuelto por decisión del equipo: actualizar D8 al mecanismo real y alinear Persistence a `mongo:8` (`ASK-006`). |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-17) |
| **Restricciones / notas** | Se conserva la implementación de healthchecks en código (aprobada por el equipo). |

#### Implementación Realizada y Verificación

**Precisión sobre el estado real (hallazgo original vs código):** el hallazgo original afirmaba que los tests de integración de Persistence estaban "fijados en `mongo:7.0`". La inspección profunda confirmó que **el código de tests ya usaba `mongo:8`** mediante el helper `mongoImage()` (`internal/infra/mongo/client_integration_test.go:27-32`, sobreescribible con `MONGO_TEST_IMAGE`); la única referencia a `mongo:7.0` estaba en el **README del repo** (líneas 35 y 112). La corrección real fue, por tanto, documental + confirmación de que el código ya cumplía D7.

**Archivos y rangos modificados**

| Archivo | Cambio |
|---|---|
| `pdf-extractext-infrastructure/docs/architecture-decisions.md` | **D8** reescrito (l.53-72): mecanismo real por servicio (`/healthprobe` en api/persistence, `python3 -c urllib … /readyz` en extraction, `mongosh ping` en Mongo), orden de arranque y justificación (distroless sin shell, sin `curl`); **D7** actualizado (l.48-52): coordinación marcada como resuelta |
| `pdf-extractext-persistence/README.md` | `mongo:7.0` → `mongo:8` en el ejemplo local (l.35) y en la nota de tests de integración (l.112) |

**Explicación técnica**

- **D8 (healthchecks):** se aprueba mantener la implementación actual por ser técnicamente superior. En imágenes `distroless` (api, persistence) no hay shell ni `curl`; el healthcheck usa el binario estático `/healthprobe` compilado en el mismo build (menor peso y menor superficie de ataque). En Extraction, se usa la librería estándar de Python (`urllib.request`) ya presente en la imagen, apuntando a `/readyz`. MongoDB usa `mongosh … db.adminCommand('ping')`. El ADR ahora documenta fielmente cada mecanismo, el orden de dependencias y la decisión descartada (`CMD-SHELL` + `curl`).
- **D7 (MongoDB):** se confirmó el pin del equipo a `mongo:8` tanto en el compose (`MONGO_IMAGE=mongo:8`) como en los tests de integración (`mongoImage()`), y se alineó la documentación del repo Persistence. El override `MONGO_TEST_IMAGE` se conserva para CPUs sin AVX.

**Comandos de prueba y resultado `[VERIFICADO-PRUEBA]`**

```
$ go build ./...                                  (en pdf-extractext-persistence)
BUILD OK
$ go vet -tags=integration ./...                  (compila los tests de integración)
VET (integration) OK
$ go test ./...                                   (tests unitarios; los de integración requieren Docker y tag)
ok  internal/api  ok  internal/config  ok  internal/domain
ok  internal/infra/mongo  ok  tests/contract
```

Nota: los tests de integración **no se ejecutaron** (requieren Docker/testcontainers y son de carga de contenedor); se verificó su **compilación** con `-tags=integration`. `[DOCUMENTADO-NO-VERIFICADO]` para la ejecución efectiva.

---

### FIND-008

| Campo | Valor |
|---|---|
| **ID** | `FIND-008` |
| **Título** | `docs/informe_tecnico.md` (versionado) presentaba métricas marcadas como "simulado" y archivos de corrida inexistentes |
| **Etapa de detección** | Re-verificación 2026-10-18 |
| **Categoría** | documentación / rendimiento |
| **Severidad** | **Alta** (un documento entregable afirmaba resultados no medidos) |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `docs/informe_tecnico.md:47-84` (sección "Comparativa de Métricas (Antes vs Después)") |
| **Descripción** | La sección 4 del informe técnico comparaba 1 vs 5 réplicas con cifras concretas (p95 850→180 ms, throughput 12→55 req/s, 503 35%→2%, 500 5%→0.1%) cuyas "fuentes" estaban rotuladas como **"Archivo de Registro (simulado)"** y apuntaban a `docs/test-runs/20261007T100000Z-k6-1-replica.md` y `...-5-replicas.md`, que **no existen**. Ninguno de esos números provino de una corrida real. |
| **Evidencia** | - `git ls-files docs/informe_tecnico.md` → versionado (commit `261d6ea`). <br> - El propio texto decía "Archivo de Registro (simulado)". <br> - `ls docs/test-runs/` → no contiene los archivos referenciados. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Riesgo alto: el informe se entrega como evidencia y podía inducir a conclusiones falsas sobre el escalado y el backpressure. |
| **Condiciones de descubrimiento** | Revisión de huecos de la Etapa 1 (el informe no había sido auditado). |
| **Causa raíz asociada** | `RC-004` |
| **Acción recomendada** | Resuelto por decisión del equipo (2026-10-18): neutralizar las cifras simuladas. |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-18). Las cifras simuladas se reemplazaron por una sección honesta "pendiente de corridas válidas" con tablas vacías; el historial de git conserva la versión anterior. |
| **Restricciones / notas** | No se inventaron métricas de reemplazo ni se usaron corridas de perfil incorrecto (ver `FIND-003`/`FIND-007`). |

---

### FIND-009

| Campo | Valor |
|---|---|
| **ID** | `FIND-009` |
| **Título** | Deriva del ADR de Infrastructure: D9 (límites "solo en desarrollo") y D5 (faltaba `API_TAG`); `.env.example` referenciaba `docs/pending-decisions.md` (eliminado) |
| **Etapa de detección** | Re-verificación 2026-10-18 |
| **Categoría** | documentación / configuración |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `docs/architecture-decisions.md` (D5, D9) y `.env.example:3` |
| **Descripción** | (a) D9 afirmaba "Resto de servicios: sin límites en desarrollo local", pero `docker-compose.yml` define límites de CPU/mem en **los 5 servicios** (traefik 0.5/512M, api 1.0/512M, extraction 1.0/1G, persistence 1.0/512M, mongodb 1.0/1G). (b) D5 omitía `API_TAG`, ya presente en el compose y el `.env.example`. (c) `.env.example` citaba `docs/pending-decisions.md`, reemplazado por `docs/architecture-decisions.md`. |
| **Evidencia** | - `docker-compose.yml` (`deploy.resources.limits` en los 5 servicios). <br> - `docs/architecture-decisions.md` D5/D9. <br> - `.env.example:3`. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo: no afecta el runtime; sí la trazabilidad de decisiones. |
| **Condiciones de descubrimiento** | Contraste ADR ↔ compose ↔ `.env.example` durante la re-verificación. |
| **Causa raíz asociada** | `RC-005` |
| **Acción recomendada** | Resuelto por decisión del equipo (2026-10-18): actualizar D9 con la tabla real, agregar `API_TAG` a D5 y corregir la referencia del `.env.example`. |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-18) |
| **Restricciones / notas** | — |

---

### FIND-010

| Campo | Valor |
|---|---|
| **ID** | `FIND-010` |
| **Título** | README de Infrastructure desalineado (decía "14 checks" y no aclaraba que PDFs/corridas son locales); `record-run.sh` podía escribir una versión de Mongo espuria |
| **Etapa de detección** | Re-verificación 2026-10-18 |
| **Categoría** | documentación / testing |
| **Severidad** | Baja |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `README.md:42`, `README.md` (§Pruebas de carga), `scripts/record-run.sh` (`mongo_version`) |
| **Descripción** | (a) El README decía que `make smoke` verifica "14 checks" cuando `scripts/smoke.sh` tiene **15**. (b) No aclaraba que los PDFs oficiales y los registros de `docs/test-runs/` son locales (gitignoreados), lo que contradecía la expectativa de que las corridas quedan versionadas. (c) `mongo_version()` encadenaba la salida de `docker exec` con `awk` mediante una construcción condicional que, si el pipeline fallaba, podía emitir la versión **y** el texto "desconocida" a la vez; dos corridas registradas (`docs/test-runs/*.md`, locales) quedaron con el texto "desconocida" colado. |
| **Evidencia** | - `scripts/smoke.sh` (checks 1–15). <br> - `README.md:42`. <br> - `docs/test-runs/20261016T214110Z-k6.md` y `...T231713Z-k6.md` (fila MongoDB con "desconocida"). |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo: confusión en conteo de checks y registros con campos mal renderizados. |
| **Condiciones de descubrimiento** | Contraste README ↔ smoke.sh y lectura de los registros locales. |
| **Causa raíz asociada** | `RC-005` |
| **Acción recomendada** | Resuelto por decisión del equipo (2026-10-18): README corregido a 15 checks + aclaraciones de artefactos locales; `mongo_version()` robustecido. |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-18) |
| **Restricciones / notas** | Los registros ya generados con "desconocida" son artefactos locales; no se reescriben. |

---

### FIND-011

| Campo | Valor |
|---|---|
| **ID** | `FIND-011` |
| **Título** | Uno de los 4 "PDFs oficiales" (`Essential-Kanban-Condensed-Spanish.pdf`) es una copia exacta de `heavy.292.pdf` del extractor |
| **Etapa de detección** | Re-verificación 2026-10-18 |
| **Categoría** | testing / rendimiento |
| **Severidad** | **Alta** (invalida la premisa de rotación de 4 documentos distintos y distorsiona el benchmark) |
| **Repositorio** | `pdf-extractext-infrastructure` (conjunto de datos) |
| **Ubicación** | `tests/load/pdfs/Essential-Kanban-Condensed-Spanish.pdf` vs `pdf-extractext-extractor/tests/data/heavy.292.pdf` |
| **Descripción** | Los dos archivos son **byte a byte idénticos**: tamaño 8.901.466 bytes y SHA-256 `257f73b908420ac5c78852fb8673beb683a8ca0c05d2e6a82b5e9629f6ad7be8` en ambos (`cmp -s` → sin diferencias). Es decir, el conjunto de carga no tiene 4 documentos oficiales distintos: uno de ellos (292 páginas, ~8,9 MB) es el PDF pesado del extractor, reetiquetado como documento Kanban. |
| **Evidencia** | - `sha256sum` de ambos archivos → mismo hash. <br> - `cmp -s heavy.292.pdf Essential-Kanban-Condensed-Spanish.pdf` → idénticos. <br> - Tamaño `8901466` en ambos. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | El perfil de Vegeta rota 4 targets pero dos apuntan al mismo contenido pesado, y ese contenido es el que explica latencias altas; la comparación con la referencia del TP (4 documentos reales) no es válida. También invalida cualquier supuesto de "distribución uniforme" entre 4 PDFs. |
| **Condiciones de descubrimiento** | Cálculo de hashes de los 4 PDFs durante la re-verificación del benchmark. |
| **Causa raíz asociada** | `RC-006` |
| **Acción recomendada** | El equipo debe reemplazar `Essential-Kanban-Condensed-Spanish.pdf` por el documento oficial real y verificar los hashes de los 4 archivos (`ASK-009`). |
| **Estado** | Abierto |
| **Restricciones / notas** | No se modificaron datos de prueba; solo se documentó el hallazgo. |

---

### FIND-012

| Campo | Valor |
|---|---|
| **ID** | `FIND-012` |
| **Título** | El backpressure de Extraction (503 + `Retry-After`) llega al cliente como 502 genérico, sin header |
| **Etapa de detección** | Verificación funcional 2026-10-18 |
| **Categoría** | contrato / configuración |
| **Severidad** | **Media** (funciona, pero el cliente no puede distinguir saturación de fallo real) |
| **Repositorio** | `pdf-extractext-api` (exige coordinación con Extraction) |
| **Ubicación** | `internal/services/extraction_client.go:72-73` (cualquier status ≠ 200 → error genérico) · `internal/api/extract.go:47` y `internal/api/upload_pdf.go:65,73` (→ 502) |
| **Descripción** | Extraction, al superar `MAX_CONCURRENCY`, responde **503 + `Retry-After`** (patrón fail-fast, ADR D10). El cliente del API descarta el status y el header del upstream y los handlers responden **502** genérico: el cliente final nunca ve el backpressure controlado que exige la consigna (503/429 con espera informada). Además, `/upload-pdf` tiene timeout de 30 s, por lo que bajo saturación el cliente percibe 502 en lugar de un rechazo inmediato. |
| **Evidencia** | - Directo contra Extraction (12 `curl` paralelos a `http://extraction:8001/extract` desde la red `services`): respuestas **503** con header `Retry-After`. <br> - Vía dominio público (14 `curl` paralelos a `https://pdf-extractext.localhost/extract`): **3×200 + 11×502**, y ningún header `Retry-After` en las respuestas. <br> - `extraction_client.go:72-73`: `if resp.StatusCode != http.StatusOK { return nil, … }` (no propaga ni el código ni el header). <br> - (Etapa 2) Un PDF corrupto produce **422** `INVALID_PDF_CONTENT` en el extractor y la API responde **502**: el enmascaramiento cubre cualquier status, no solo el 503. |
| **Etiqueta de taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | El cliente (y las herramientas de carga) trata saturación como fallo: reintenta en el momento y empeora la cola. Se pierde la señal de "esperá N segundos" que es el núcleo del manejo de congestión del TP. |
| **Condiciones de descubrimiento** | Prueba de saturación manual con `curl` concurrente durante la verificación funcional del sistema (2026-10-18). |
| **Causa raíz asociada** | `RC-007` |
| **Acción recomendada** | Propagar el 503 y el header `Retry-After` del extractor en `/extract` y `/upload-pdf` (y documentarlos en el README/OpenAPI). Requiere decisión y cambio de comportamiento en el API. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (commit API `fb3d7c3`, 2026-10-19) — los 4xx y el 503 del extractor se propagan tal cual (503 conserva `Retry-After`); 502 solo para fallos de red/timeout o 500 del upstream. Verificado en runtime (curas en vivo, C-21). |
| **Restricciones / notas** | ~~Prioridad: primero el funcionamiento correcto; corrección diferida.~~ Resuelto en la fase de correcciones aprobada. Las pruebas de carga (k6/Vegeta) quedan para la etapa final (`FIND-003`, `FIND-007`). |

---

### FIND-013

| Campo | Valor |
|---|---|
| **ID** | `FIND-013` |
| **Título** | Un id malformado en `GET /documents/{id}` responde **500** en la API (Persistence devuelve 400) |
| **Etapa de detección** | Etapa 2 — auditoría funcional (2026-10-18) |
| **Categoría** | contrato / errores |
| **Severidad** | **Media** (un error de cliente se reporta como fallo interno; contamina el monitoreo con 5xx) |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `internal/services/persistence_client.go:106-111` (`FindByID` solo traduce 404/200; cualquier otro status → error genérico) · `internal/api/documents.go:52-58` |
| **Descripción** | Persistence valida el formato del id y responde 400 `INVALID_REQUEST` (`pdf-extractext-persistence/internal/api/documents.go:129-132`). El cliente de la API no propaga ese 400 y el `CustomErrorHandler` cae al fallback 500 `INTERNAL_ERROR`. Misma causa raíz que `FIND-012` (RC-007), pero en el salto API→Persistence. |
| **Evidencia** | `curl https://pdf-extractext.localhost/documents/xyz` → **500** `{"code":"INTERNAL_ERROR","message":"error interno del servidor"}` (runtime 2026-10-18); el id válido inexistente (`aaaaaaaaaaaaaaaaaaaaaaaa`) → **404** correcto. |
| **Etiquetas de taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | El cliente corrige mal su petición (espera 500 y no reintenta con id válido); los tableros de error cuentan 5xx por tráfico inválido. |
| **Condiciones de descubrimiento** | Trazado del CRUD de `/documents` en la Etapa 2 con `curl` sobre el stack real. |
| **Causa raíz asociada** | `RC-007` |
| **Acción recomendada** | Validar el formato del id en la API o mapear 4xx del upstream a su status original (junto con la corrección de `FIND-012`). |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (commit API `fb3d7c3`, 2026-10-19) — id hex-24 validado en la API (GET/PATCH/DELETE) y el `UpstreamError` re-emite el 400 de Persistence sin convertirlo en 500. Verificado en runtime (C-21). |
| **Restricciones / notas** | ~~Corrección diferida.~~ Resuelto en la fase de correcciones aprobada. |

---

### FIND-014

| Campo | Valor |
|---|---|
| **ID** | `FIND-014` |
| **Título** | La API no propaga `X-Request-ID` a Persistence: se rompe la correlación distribuida |
| **Etapa de detección** | Etapa 2 — auditoría funcional (2026-10-18) |
| **Categoría** | observabilidad / trazabilidad |
| **Severidad** | **Baja** (no afecta funcionalidad; dificulta el diagnóstico end-to-end) |
| **Repositorio** | `pdf-extractext-api` |
| **Ubicación** | `internal/services/persistence_client.go` (ninguno de los 5 métodos setea `X-Request-ID`) vs `internal/services/extraction_client.go:62-64` (sí lo propaga) y `pdf-extractext-persistence/internal/api/middleware.go:32-49` (acepta y usa el header) |
| **Descripción** | El middleware de la API acepta/genera `X-Request-ID` y lo reenvía a Extraction, pero el cliente de Persistence nunca lo envía; Persistence genera entonces un UUID propio. Dos request-ids distintos describen la misma petición en los logs del sistema. |
| **Evidencia** | `curl https://pdf-extractext.localhost/documents -H 'X-Request-ID: etapa2-audit-001'` → 200, y `docker logs pdf-extractext-persistence-1` no contiene `etapa2-audit-001` (generó otro UUID) — runtime 2026-10-18. |
| **Etiquetas de taxonomía** | `[VERIFICADO-PRUEBA]` |
| **Impacto** | No se puede rastrear una petición completa en los logs de los 4 servicios con un solo id. |
| **Condiciones de descubrimiento** | Verificación de correlación entre servicios en la Etapa 2. |
| **Causa raíz asociada** | `RC-008` |
| **Acción recomendada** | Setear `X-Request-ID` en los 5 métodos de `persistence_client.go`, igual que hace el cliente de Extraction. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (commit API `fb3d7c3`, 2026-10-19) — los 5 métodos del cliente de Persistence envían `X-Request-ID` (helper `newRequest`). Verificado en runtime (C-21). |
| **Restricciones / notas** | ~~Sin corrección en esta etapa.~~ Resuelto en la fase de correcciones aprobada. |

---

### FIND-015

| Campo | Valor |
|---|---|
| **ID** | `FIND-015` |
| **Título** | El 503 de saturación del extractor declara `code: "INTERNAL_ERROR"` |
| **Etapa de detección** | Etapa 2 — auditoría funcional (2026-10-18) |
| **Categoría** | contrato / errores |
| **Severidad** | **Baja** (el status y `Retry-After` son correctos; solo el code del envelope es semánticamente erróneo) |
| **Repositorio** | `pdf-extractext-extractor` |
| **Ubicación** | `src/pdf_extractext_extractor/admission.py:45-51` (503 con `code: "INTERNAL_ERROR"`) · `errors.py:4-9` (catálogo sin entrada de saturación) |
| **Descripción** | El catálogo de errores define 400/422/500 pero no un code para saturación; el middleware de admisión reutiliza `INTERNAL_ERROR` en el 503. Un cliente que decida por `code` (y no por status) tratará una condición transitorio como fallo interno permanente. |
| **Evidencia** | `[VERIFICADO-CÓDIGO]` `admission.py:45-51` devuelve `{"code":"INTERNAL_ERROR","message":"Servicio saturado…"}` con header `Retry-After`. |
| **Etiquetas de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Semántica de error engañosa en el contrato del extractor; el envelope contradice al status. |
| **Condiciones de descubrimiento** | Revisión de los contratos de error de los 3 servicios en la Etapa 2. |
| **Causa raíz asociada** | `RC-009` |
| **Acción recomendada** | Añadir un code dedicado (p. ej. `SERVICE_OVERLOADED`) al catálogo del extractor y usarlo en el 503. |
| **Estado** | `[RESUELTO - IMPLEMENTADO]` (commit extractor `627aecf`, 2026-10-19) — catálogo `PROBLEM_CATALOG` con `SERVICE_OVERLOADED` y 503 en `application/problem+json` (RFC 9457). Verificado en runtime (C-21). |
| **Restricciones / notas** | ~~Sin corrección en esta etapa.~~ Resuelto junto con la adopción de RFC 9457 (`CON-018`). |
