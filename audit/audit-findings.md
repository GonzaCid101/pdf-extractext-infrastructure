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
| `RC-004` | El informe técnico se redactó con datos de ejemplo/simulados en lugar de corridas reales y no se reemplazaron al obtener mediciones. | `FIND-008` | Propuesta | `[HIPÓTESIS]` |
| `RC-005` | Los documentos de infraestructura (ADR, README, `.env.example`) evolucionaron sin una revisión de consistencia cruzada tras cada cambio de implementación. | `FIND-009`, `FIND-010` | Propuesta | `[HIPÓTESIS]` |
| `RC-006` | El conjunto de PDFs de carga se armó copiando archivos sin verificar su procedencia/hash, dejando un duplicado del PDF pesado del extractor. | `FIND-011` | Propuesta | `[HIPÓTESIS]` |

---

## Hallazgos (`FIND-XXX`)

### FIND-001

| Campo | Valor |
|---|---|
| **ID** | `FIND-001` |
| **Título** | Los 4 PDFs oficiales no están versionados: presentes en disco local pero excluidos por `.gitignore` |
| **Etapa de detección** | Etapa 1 (re-verificado 2026-10-18) |
| **Categoría** | testing / configuración |
| **Severidad** | Media (ya no bloquea las corridas en este entorno, pero impide reproducir la línea base desde un clon limpio) |
| **Repositorio** | Workspace `Microservicios/` (los 4 repos) |
| **Ubicación** | `pdf-extractext-infrastructure/tests/load/pdfs/` (4 PDFs presentes) y `.gitignore:15-21` (`tests/load/pdfs/*.pdf`). La ruta de la cátedra `tests/stress/pdfs` sigue sin existir en ningún repo. |
| **Descripción** | **Re-verificación 2026-10-18:** los 4 PDFs oficiales (`2020-Scrum-Guide-Spanish-Latin-South-American.pdf`, `Essential-Kanban-Condensed-Spanish.pdf`, `Filosofia Lean.pdf`, `scrum_manager_historias_usuario.pdf`) **están presentes** en `tests/load/pdfs/`, por lo que `make load-k6` y `make load-vegeta` pueden ejecutarse localmente. Sin embargo **no están versionados** (`.gitignore` los excluye): un clon limpio no los tiene, así que la línea base no es reproducible sin una copia manual. La ruta del enunciado `tests/stress/pdfs` sigue sin existir (se usa `tests/load/pdfs`). |
| **Evidencia** | - `ls tests/load/pdfs/` → los 4 `.pdf` + `generate_fixtures.sh`. <br> - `git ls-files tests/load/pdfs` → solo `generate_fixtures.sh` (los PDFs no están trackeados). <br> - `git status --ignored` → los 4 `.pdf` figuran como `!!` (ignorados). <br> - `find … -type d -name stress` → sin resultados. |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Las corridas son posibles en este equipo pero no reproducibles en un clon limpio ni auditables desde git; persiste el riesgo de que cada integrante use un conjunto distinto. |
| **Condiciones de descubrimiento** | Re-verificación del filesystem y de `git ls-files`/`git status --ignored` (2026-10-18). |
| **Causa raíz asociada** | `RC-001` |
| **Acción recomendada** | Documentar que los PDFs son locales y cómo obtenerlos (hecho el 2026-10-18 en `README.md` y `.gitignore`). El equipo debe confirmar si `tests/stress/pdfs` (enunciado) designa el mismo conjunto (`ASK-002`). |
| **Estado** | Abierto (parcialmente mitigado). Decisión del equipo 2026-10-18: **no versionarlos**. |
| **Restricciones / notas** | Se mantienen fuera de git por peso y por ser provistos por la cátedra. No se regeneran ni se sustituyen por fixtures artificiales. |

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
| **Ubicación** | `.gitignore:15-18` y `README.md` (sección de pruebas de carga) |
| **Descripción** | El comentario del `.gitignore` decía que los PDFs "ya están copiados en el repositorio" mientras la línea siguiente los ignoraba (`tests/load/pdfs/*.pdf`); el README afirmaba que el conjunto oficial era "Sin `generate_fixtures.sh`", dando a entender que estaba versionado. **Resolución 2026-10-18:** ambos textos se reescribieron para declarar que los PDFs son **locales y no se versionan**, y que el registro de corridas (`docs/test-runs/`) también es local. |
| **Evidencia** | - Estado previo: `.gitignore:15-18`, `README.md` (§Pruebas de carga). <br> - Estado actual: `.gitignore` ("NO se versionan… cada dev los copia localmente") y `README.md` (bullets "PDFs oficiales" y "Registro de corridas"). |
| **Etiqueta de taxonomía** | `[VERIFICADO-CÓDIGO]` |
| **Impacto** | Bajo tras la corrección: se elimina la falsa expectativa de que el entorno de carga está completo en un clon limpio. |
| **Condiciones de descubrimiento** | Contraste entre textos documentales y el listado/trackeo real del directorio. |
| **Causa raíz asociada** | `RC-001` |
| **Acción recomendada** | Resuelto por decisión del equipo (2026-10-18): mantener los PDFs fuera de git y documentarlo. |
| **Estado** | **`[RESUELTO - IMPLEMENTADO]`** (2026-10-18) |
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
