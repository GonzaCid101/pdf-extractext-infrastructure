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
| `RC-001` | El conjunto oficial de PDFs nunca se commiteó (excluido por `.gitignore`) y el comentario del `.gitignore`/README quedó desalineado con el estado real del repo. | `FIND-001`, `FIND-002` | Propuesta — requiere confirmación del equipo | `[HIPÓTESIS]` |
| `RC-002` | Los README de los tres servicios no se actualizaron tras la implementación de funcionalidad posterior al bootstrap (issues de extracción, persistencia y orquestación). | `FIND-004` | Propuesta | `[HIPÓTESIS]` |
| `RC-003` | Coexisten dos suites de carga (una del repo Extractor y una de Infrastructure) sin definir cuál es la canónica del TP. | `FIND-003` | Propuesta | `[HIPÓTESIS]` |

---

## Hallazgos (`FIND-XXX`)

### FIND-001

| Campo | Valor |
|---|---|
| **ID** | `FIND-001` |
| **Título** | Ausencia del conjunto oficial de PDFs de prueba; `tests/stress/pdfs` no existe en ningún repositorio |
| **Etapa de detección** | Etapa 1 |
| **Categoría** | testing / rendimiento |
| **Severidad** | **Alta** (bloquea los benchmarks reales de la Etapa 3/4; NO bloquea la auditoría estática de Etapas 2, 3A, 3B, 3C y 4) |
| **Repositorio** | Workspace `Microservicios/` (los 4 repos) |
| **Ubicación** | No existe ningún directorio `tests/stress/` en: `pdf-extractext-api`, `pdf-extractext-extractor`, `pdf-extractext-persistence`, `pdf-extractext-infrastructure`. El único PDF real del workspace es `pdf-extractext-extractor/tests/data/heavy.292.pdf`. |
| **Descripción** | El enunciado de la cátedra exige usar el "conjunto oficial de PDFs en `tests/stress/pdfs`". La búsqueda exhaustiva (`find -type d -name stress`, `find -iname "*.pdf"`) no encontró esa ruta ni esos archivos en ningún repo. En su lugar, Infrastructure declara `tests/load/pdfs/` como carpeta de PDFs de carga, pero contiene únicamente el script generador `generate_fixtures.sh`; los 4 PDFs oficiales que esperan `run_vegeta.sh:34-43` y `spike_tests.js:17-22` no están en disco. |
| **Evidencia** | - `find /Microservicios -type d -name stress` → sin resultados. <br> - `find /Microservicios -iname "*.pdf"` → 1 resultado: `extractor/tests/data/heavy.292.pdf` (8.901.466 bytes, SHA-256 `257f73b908420ac5c78852fb8673beb683a8ca0c05d2e6a82b5e9629f6ad7be8`). <br> - `infrastructure/tests/load/pdfs/` → solo `generate_fixtures.sh`. <br> - `infrastructure/tests/load/vegeta/run_vegeta.sh:34-39` lista: `2020-Scrum-Guide-Spanish-Latin-South-American.pdf`, `Essential-Kanban-Condensed-Spanish.pdf`, `Filosofia Lean.pdf`, `scrum_manager_historias_usuario.pdf`. <br> - `infrastructure/.gitignore:18`: `tests/load/pdfs/*.pdf`. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` (ausencia verificada por inspección directa del filesystem) |
| **Impacto** | No se pueden ejecutar `make load-k6` ni `make load-vegeta` con los PDFs oficiales; no es posible reproducir ni contrastar las cifras de referencia del TP. Tampoco queda claro si `tests/stress/pdfs` (cátedra) y `tests/load/pdfs` (repo) designan el mismo conjunto. |
| **Condiciones de descubrimiento** | Búsqueda selectiva del árbol de directorios de los 4 repos ignorando `node_modules`, `.git`, `.venv`, `__pycache__`, `dist`, `build`. |
| **Causa raíz asociada** | `RC-001` |
| **Acción recomendada** | El equipo debe copiar los 4 PDFs oficiales en `tests/load/pdfs/` (antes de correr benchmarks) y confirmar si la ruta del enunciado `tests/stress/pdfs` debe tratarse como sinónimo (`ASK-001`, `ASK-002`). |
| **Estado** | Abierto |
| **Restricciones / notas** | No se regeneran ni sustituyen por fixtures artificiales (el propio `.gitignore:15-17` lo prohíbe). La auditoría no modifica datos de prueba. |

---

### FIND-002

| Campo | Valor |
|---|---|
| **ID** | `FIND-002` |
| **Título** | Contradicción documental: `.gitignore` y README de Infrastructure afirman que los 4 PDFs oficiales "ya están copiados en el repositorio", pero no existen en disco |
| **Etapa de detección** | Etapa 1 |
| **Categoría** | documentación / configuración |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-infrastructure` |
| **Ubicación** | `.gitignore:15-18`, `README.md:86-87` ("PDFs oficiales (`tests/load/pdfs/`): los 4 del profesor. **Sin** `generate_fixtures.sh`") vs contenido real de `tests/load/pdfs/` (solo `generate_fixtures.sh`) |
| **Descripción** | El comentario del `.gitignore` dice textualmente que los PDFs "ya están copiados en el repositorio", y el README afirma que el conjunto oficial es "Sin `generate_fixtures.sh`". Ambas afirmaciones se contradicen con el estado real: no hay ningún `.pdf` en el repo y el único archivo presente en la carpeta es exactamente `generate_fixtures.sh`. |
| **Evidencia** | - `.gitignore:15-17`: "PDFs oficiales del conjunto de prueba (tests/load/pdfs/): ya están copiados en el repositorio, no se regeneran con generate_fixtures.sh". <br> - `.gitignore:18`: `tests/load/pdfs/*.pdf` (ignora los PDFs aunque el comentario diga que están versionados). <br> - `README.md:86-87`. <br> - `ls tests/load/pdfs/` → solo `generate_fixtures.sh` (3.275 bytes). |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Falsa sensación de que el entorno de carga está completo; cualquier `make load-vegeta` falla con "ERROR: falta tests/load/pdfs/…". |
| **Condiciones de descubrimiento** | Contraste entre textos documentales y listado real del directorio. |
| **Causa raíz asociada** | `RC-001` |
| **Acción recomendada** | Actualizar comentario del `.gitignore` y README cuando el equipo confirme el mecanismo de distribución de los PDFs (fuera del alcance de esta auditoría: no se modifican archivos fuera de `audit/`). |
| **Estado** | Abierto |
| **Restricciones / notas** | Contradicción documental registrada también como `CON-001`/`CON-002` en `audit-decisions.md`. |

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
| **Ubicación** | `Makefile:57-58` → `tests/load/run_k6.sh:21` → `tests/load/spike_tests.js:8-12` (stages `target: 1`); `tests/load/k6-spike.js:30-38` (stages `target: 100`, perfil exacto del TP 10s/20s/10s) sin referencia desde ningún script o target |
| **Descripción** | El README (`README.md:75, 81-83`) documenta `make load-k6` como "spike: 10s→100 VUs, 20s, 10s→0". En la implementación real, `run_k6.sh` ejecuta `spike_tests.js`, cuyas stages suben a **1 VU** (`{ duration: '20s', target: 1 }`). El script que sí implementa el perfil del TP (100 VUs, con métricas p50/p90/p95 e `insecureSkipTLSVerify`) es `k6-spike.js`, y no está cableado a ningún target del Makefile ni invocado por `run_k6.sh`. Adicionalmente, `spike_tests.js` depende de los 4 PDFs oficiales ausentes (`FIND-001`). |
| **Evidencia** | - `Makefile:57-58`: `load-k6: check` → `bash tests/load/run_k6.sh`. <br> - `run_k6.sh:21`: `k6 run --summary-export=… ${K6_ARGS:-} tests/load/spike_tests.js`. <br> - `spike_tests.js:9-11`: stages `target: 1`. <br> - `k6-spike.js:32-36`: stages `target: 100`, duración total 40s (coincide con la referencia 1.037 reqs en 40s). <br> - Grep: `k6-spike.js` no aparece en `Makefile`, `run_k6.sh` ni README. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Ejecutar el benchmark tal como está cableado NO reproduce el escenario del TP (100 VUs); las métricas resultantes no serían comparables con la referencia (P50 1,88s, P90 7,83s, 25,35 req/s). |
| **Condiciones de descubrimiento** | Lectura cruzada Makefile → run_k6.sh → scripts k6, contrastando con el perfil del enunciado. |
| **Causa raíz asociada** | `RC-003` |
| **Acción recomendada** | El equipo debe definir cuál script es el canónico del TP (`ASK-003`). La auditoría no modifica scripts. |
| **Estado** | Abierto |
| **Restricciones / notas** | `k6-spike.js` usa fixtures generados (`fixture-1p/3p/8p/20p.pdf`) mientras `spike_tests.js` usa los 4 PDFs oficiales: son dos enfoques distintos de fixture, otro motivo para definir el canónico. |

---

### FIND-004

| Campo | Valor |
|---|---|
| **ID** | `FIND-004` |
| **Título** | READMEs de API, Extraction y Persistence desactualizados respecto del código real |
| **Etapa de detección** | Etapa 1 |
| **Categoría** | documentación |
| **Severidad** | Media |
| **Repositorio** | `pdf-extractext-api`, `pdf-extractext-extractor`, `pdf-extractext-persistence` |
| **Ubicación** | Ver evidencia por servicio |
| **Descripción** | Los tres README describen un estado "bootstrap" que el código ya superó: <br> **(a) API** `README.md:78-86, 134-150`: dice que `PERSISTENCE_URL` es "requisito muerto… ningún código la consume" (issue #6), que `/extract` "no registrado aún" y que no hay endpoints CRUD; el código real registra `POST /extract`, `POST /upload-pdf` y CRUD `/documents` con `persistence_client.go` (`cmd/api/main.go:32-40`). <br> **(b) Extraction** `README.md:3, 36-37`: dice "bootstrap inicial… fase actual: recepción" y que la respuesta es `{filename, size}`; el código real extrae texto con PyMuPDF y responde `content`, `page_count`, `checksum` (`extraction.py:10-15`, `domain/extractor.py`). <br> **(c) Persistence** `README.md:5`: dice "El CRUD y el repositorio se implementarán en etapas posteriores"; `router.go:26-30` registra CRUD completo (`POST/GET/PATCH/DELETE /documents`). |
| **Evidencia** | Códigos citados arriba leídos directamente. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Riesgo de decisiones de auditoría basadas en documentación vieja; enmascara funcionalidad ya implementada (p. ej. la orquestación API→Persistence). |
| **Condiciones de descubrimiento** | Comparación de README vs `main.go`, `router.go` y `extraction.py` durante el inventario tecnológico. |
| **Causa raíz asociada** | `RC-002` |
| **Acción recomendada** | Actualizar READMEs en sus repos (fuera del alcance de la auditoría). |
| **Estado** | Abierto |
| **Restricciones / notas** | — |

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
| **Acción recomendada** | El equipo debe confirmar el rate intencional (`ASK-008`). La auditoría NO modifica scripts. |
| **Estado** | Abierto |
| **Restricciones / notas** | No se ejecutó el script (restricción de no correr cargas); el análisis es 100% estático del código. |

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
