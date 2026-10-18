# Audit Decisions — PDF Extractext

Registro de decisiones arquitectónicas a verificar, contradicciones documentales detectadas y preguntas para el equipo.
Fuente primaria de decisiones: `pdf-extractext-infrastructure/docs/architecture-decisions.md` (ADR D1–D15).

---

## Decisiones arquitectónicas a verificar (`DEC-XX`)

Mapeo 1:1 con el ADR de Infrastructure. Estado = lo que la auditoría pudo confirmar estáticamente en la Etapa 1.

| ID | ADR origen | Decisión | Verificación Etapa 1 | Estado |
|---|---|---|---|---|
| `DEC-01` | D1 | Traefik v3 con TLS local (mkcert), entrypoints :80→:443 | `traefik/traefik.yml` y compose (`traefik:v3`, puertos 80/443) consistentes con la decisión | `[VERIFICADO-CÓDIGO]` parcial (runtime pendiente Etapa 3) |
| `DEC-02` | D2 | Dominio local `pdf-extractext.localhost`; certs no versionados | `.gitignore:13` ignora `traefik/certs/`; carpeta `traefik/certs/` presente y vacía en disco | `[VERIFICADO-CÓDIGO]` |
| `DEC-03` | D3 | Routing interno API→Extraction vía Traefik entrypoint `internal` :8090 no publicado | Compose: extraction con label `entrypoints=internal`, :8090 sin `ports:`; API con `EXTRACTION_URL=http://traefik:8090` | `[VERIFICADO-CÓDIGO]` |
| `DEC-04` | D4 | Aislamiento por redes `services` / `data`; solo Persistence en `data` | `docker-compose.yml:152-154` + pertenencia de servicios; grep confirma que Extraction no referencia Mongo/Persistence | `[VERIFICADO-CÓDIGO]` |
| `DEC-05` | D5 | Tags de imagen parametrizables (`*_TAG`, default `dev`) | `.env.example`, compose (`image: …:${API_TAG:-dev}`, etc.) | `[VERIFICADO-CÓDIGO]` |
| `DEC-06` | D6 | Build desde repos hermanos (`*_CONTEXT`) | `.env.example:9-25`, `Makefile:check` valida existencia de contextos y Dockerfiles | `[VERIFICADO-CÓDIGO]` |
| `DEC-07` | D7 | MongoDB `mongo:8` definitivo; coordinar Persistence (tests en `mongo:7.0`) | **RESUELTO (2026-10-17):** el código de tests ya usaba `mongo:8` (`mongoImage()`); se alineó el README de Persistence a `mongo:8` y D7 en el ADR (`FIND-006`). Compilación verificada con `go vet -tags=integration` | **`[RESUELTO - IMPLEMENTADO]`** |
| `DEC-08` | D8 | Healthchecks in-container + `depends_on: service_healthy` | **RESUELTO (2026-10-17):** D8 reescrito documentando el mecanismo real (`/healthprobe` en api/persistence, `python3 -c urllib … /readyz` en extraction, `mongosh ping` en Mongo), orden de arranque y justificación de no usar `curl` en distroless (`FIND-006`) | **`[RESUELTO - IMPLEMENTADO]`** |
| `DEC-09` | D9 | Límites CPU/mem por instancia; réplicas Extraction 1–5 | Compose: límites en los 5 servicios; `Makefile:22-25` valida rango 1–5. **ADR D9 corregido el 2026-10-18** (antes decía "resto sin límites", contradiciendo al compose) → `FIND-009` | `[VERIFICADO-CÓDIGO]` |
| `DEC-10` | D10 | Saturación = 503 + `Retry-After` implementado por Extraction | `admission.py` + `errors.py` en extractor; middleware de admisión presente | `[VERIFICADO-CÓDIGO]` (comportamiento bajo carga: pendiente Etapa 3/4) |
| `DEC-11` | D11 | Herramientas de carga: k6 (spike 100 VUs, abierto ≥25 req/s) + Vegeta (50 req/s × 30s, timeout 30s) | Perfil de duración/timeout de Vegeta coincide (`DURATION=30s`, `TIMEOUT=30s`, `-insecure`), **pero el rate está en 1/s, no 50/s** → `FIND-007`; **k6 cableado a 1 VU** → `FIND-003` | `[VERIFICADO-CÓDIGO]` con gaps en ambas herramientas |
| `DEC-12` | D12 | Sin CI por ahora; smoke local | Existe `.github/workflows/ci.yml` solo en `pdf-extractext-api` (repo propio); Infrastructure sin CI, `make smoke` local | `[VERIFICADO-CÓDIGO]` |
| `DEC-13` | D13 | Stack fijo: Compose v2, Traefik v3, Mongo oficial, Make, Bash, curl; sin herramientas extra | Consistente con compose/Makefile/README | `[VERIFICADO-CÓDIGO]` |
| `DEC-14` | D14 | Contrato Extraction: solo `multipart/form-data` (campo `file`) → `{content, page_count}` | API y extractor implementan multipart campo `file`; API responde exactamente `{content, page_count}`. Pregunta abierta del ADR sobre quién calcula el SHA-256 sigue sin resolverse en el código de orquestación (`upload_pdf.go` usa checksum del extractor) | `[VERIFICADO-CÓDIGO]` parcial / `[DECISIÓN-PENDIENTE]` (checksum) |
| `DEC-15` | D15 | API declarada en el compose (✅ resuelta) | Compose define servicio `api` con build `${API_CONTEXT}`, red `services`, env `EXTRACTION_URL`/`PERSISTENCE_URL`/`MAX_FILE_SIZE_MB=50`, router público TLS | `[VERIFICADO-CÓDIGO]` |

Nota: el README de API (`README.md:26-27`) aún afirma que "esta API todavía no está declarada en ese compose" — contradicción con D15 y con el compose real → `CON-006`.

---

## Contradicciones documentales detectadas (`CON-XX`)

| ID | Contradicción | Fuente A | Fuente B | Hallazgo | Estado |
|---|---|---|---|---|---|
| `CON-001` | README de Infrastructure: "PDFs oficiales (tests/load/pdfs/): los 4 del profesor. **Sin** generate_fixtures.sh" | `README.md` (sección de carga) | Realidad: los PDFs existen y ahora **se versionan** en el repo | `FIND-002` | **Resuelta** (2026-10-18: PDFs versionados; README actualizado) |
| `CON-002` | `.gitignore` comentaba que los PDFs "ya están copiados en el repositorio" pero los ignoraba con `tests/load/pdfs/*.pdf` | `.gitignore` | Realidad: ahora la regla de exclusión se eliminó y se versionan | `FIND-002` | **Resuelta** (2026-10-18) |
| `CON-003` | README de API describía bootstrap sin orquestación ni persistencia | `README.md` (previo) | `cmd/api/main.go:36-40` (registra `/extract`, `/upload-pdf`, CRUD `/documents`) | `FIND-004` | **Resuelta** (2026-10-18: README reescrito) |
| `CON-004` | README de Extraction: "solo recepción", respuesta `{filename, size}` | `README.md` (previo) | `extraction.py` + `domain/extractor.py` (extracción real con PyMuPDF a Markdown) | `FIND-004` | **Resuelta** (2026-10-18: README actualizado) |
| `CON-005` | README de Persistence: "CRUD en etapas posteriores" | `README.md` (previo) | `internal/api/router.go:26-37` (CRUD + probes completos) | `FIND-004` | **Resuelta** (2026-10-18: README actualizado) |
| `CON-006` | README de API: "Esta API todavía no está declarada en ese compose" | `README.md` (previo) | Infrastructure `docker-compose.yml` define el servicio `api` (D15 resuelta) | `FIND-004` | **Resuelta** (2026-10-18: README actualizado) |
| `CON-007` | README de Infrastructure documenta `make load-k6` como spike a 100 VUs; el script ejecutado usa 1 VU | `README.md:75, 81-83` | `run_k6.sh:21` → `spike_tests.js:9-11` (`target: 1`) | `FIND-003` | Abierta |
| `CON-008` | Enunciado de la cátedra: `tests/stress/pdfs`; repos: `tests/load/pdfs` (ahora con los 4 PDFs versionados) | Enunciado TP | Filesystem de los 4 repos | `FIND-001` | Abierta (`ASK-002`) |
| `CON-009` | ADR D8 describe healthchecks con `curl` + CMD-SHELL; implementación real usa binario `/healthprobe` y `python3 -c urllib` | `architecture-decisions.md:55` | `docker-compose.yml:45-48, 93-98, 121-126` | `FIND-006` | **Resuelta** (D8 reescrito) |
| `CON-010` | Enunciado pide `content` convertido a Markdown; el código extrae texto plano y ningún repo contiene código Markdown | Enunciado TP | `domain/extractor.py:35`; grep `markdown` = 0 resultados | `FIND-005` | **Resuelta** (`ASK-005`; Markdown implementado) |
| `CON-011` | `run_vegeta.sh`, README y ADR D11 documentan "50 req/s × 30s"; el script está hardcoded a `RATE="1/s"` (~30 reqs en 30s, no 1.500) | `run_vegeta.sh:2,21`, `README.md:76`, `architecture-decisions.md:71` | `run_vegeta.sh:21,71` (`RATE="1/s"`, `-rate="$RATE"`) | `FIND-007` | Abierta (`ASK-008`) |
| `CON-012` | El informe técnico presentaba métricas de scaling como reales citando archivos "simulado" inexistentes | `informe_tecnico.md:47-84` (versión previa) | `docs/test-runs/` no contiene `20261007T100000Z-k6-1-replica.md` ni `...-5-replicas.md` | `FIND-008` | **Resuelta** (2026-10-18: sección neutralizada) |
| `CON-013` | ADR D9 decía "resto de servicios: sin límites en desarrollo local"; el compose fija límites en los 5 servicios | `architecture-decisions.md` D9 (previo) | `docker-compose.yml` (5 × `deploy.resources.limits`) | `FIND-009` | **Resuelta** (2026-10-18: D9 corregido) |
| `CON-014` | `.env.example` citaba `docs/pending-decisions.md`, archivo eliminado y reemplazado por `docs/architecture-decisions.md` | `.env.example:3` (previo) | `docs/architecture-decisions.md` existe; `docs/pending-decisions.md` no | `FIND-009` | **Resuelta** (2026-10-18) |
| `CON-015` | README de Infrastructure decía que `make smoke` verifica "14 checks"; el script implementa 15 | `README.md:42` (previo) | `scripts/smoke.sh` (checks 1–15) | `FIND-010` | **Resuelta** (2026-10-18: README corregido) |
| `CON-016` | El conjunto de carga se presenta como "4 PDFs oficiales" distintos, pero `Essential-Kanban-Condensed-Spanish.pdf` es idéntico a `heavy.292.pdf` del extractor | `tests/load/pdfs/Essential-Kanban-Condensed-Spanish.pdf` | `pdf-extractext-extractor/tests/data/heavy.292.pdf` (mismo SHA-256) | `FIND-011` | Abierta |
| `CON-017` | Consigna y ADR D10 exigen saturación visible (503 + `Retry-After`); Extraction la emite, pero el API responde 502 genérico sin header | `consigna.md` (mitigación de saturación), `architecture-decisions.md` D10 | `extraction_client.go:72-73` + `extract.go:47`/`upload_pdf.go:65,73` (todo status ≠ 200 → 502) | `FIND-012` | Abierta (corrección diferida: primero funcionamiento, carga al final) |

---

## Preguntas para el equipo (`ASK-XX`)

| ID | Pregunta | Contexto | Bloquea | Prioridad |
|---|---|---|---|---|
| `ASK-001` | ~~¿Pueden copiar los 4 PDFs oficiales (`2020-Scrum-Guide-Spanish-Latin-South-American.pdf`, `Essential-Kanban-Condensed-Spanish.pdf`, `Filosofia Lean.pdf`, `scrum_manager_historias_usuario.pdf`) a `tests/load/pdfs/` del repo Infrastructure?~~ | **`[RESUELTO]` (2026-10-18).** Los 4 PDFs están presentes y ahora **se versionan** en `tests/load/pdfs/` (se eliminó la exclusión de `.gitignore`). Ver `FIND-001`; queda abierto el dato duplicado (`FIND-011`). | Benchmarks reales (Etapa 3/4) | — |
| `ASK-002` | ¿La ruta del enunciado `tests/stress/pdfs` designa el mismo conjunto que `tests/load/pdfs` del repo, o existe otro repositorio/carpetas no clonados en este workspace? | Ningún repo contiene `tests/stress/`; el workspace solo tiene los 4 repos clonados. | Clarar alcance del conjunto oficial | **Alta** |
| `ASK-003` | ~~¿Cuál es el script k6 canónico del TP: `k6-spike.js` (100 VUs, usa fixtures generados `fixture-*.pdf`) o `spike_tests.js` (1 VU, usa los 4 PDFs oficiales)? `make load-k6` hoy ejecuta el segundo.~~ | **`[RESUELTO]` (2026-10-18).** Canónico = `spike_tests.js`; `k6-spike.js` y `generate_fixtures.sh` fueron eliminados. El salto a 100 VUs queda pendiente hasta la etapa final de benchmarks (`FIND-003`). | Comparabilidad de resultados k6 con la referencia | — |
| `ASK-004` | ¿Dónde están registradas las corridas que produjeron las cifras de referencia (1.037 reqs / 25,35 req/s k6; 998 exitosas / 501 timeouts Vegeta)? | **Parcialmente respondida (2026-10-18):** existen 5 corridas locales en `docs/test-runs/` (3 k6 + 2 Vegeta, del 2026-10-16), pero están **gitignoreadas** (no versionadas) y usan los perfiles aún no corregidos (`FIND-003`/`FIND-007`), por lo que no son comparables con la referencia del TP. | Contraste de benchmarks | Media |
| `ASK-005` | ~~¿"content convertido a Markdown cuando corresponda" exige transformación real o acepta texto plano?~~ | **`[RESUELTO E IMPLEMENTADO]` (2026-10-17).** El equipo decidió implementar conversión real a Markdown nativo en el extractor. Ver "Registro de Resoluciones" abajo. | — | — |
| `ASK-006` | ~~¿Se alinean los tests de integración de Persistence a `mongo:8` (D7) o se mantiene `mongo:7.0`?~~ | **`[RESUELTO E IMPLEMENTADO]` (2026-10-17).** Confirmado `mongo:8` en tests y README; D7/D8 del ADR actualizados. Ver "Registro de Resoluciones" abajo. | — | — |
| `ASK-007` | ¿Es correcto tratar `.env` de Infrastructure como artefacto local no auditado (contiene credenciales dev)? Confirmar si hay algún valor crítico distinto de `.env.example` que debamos conocer. | El `.env` existe en disco pero no fue releído por contención con secretos. | Claridad de entorno | Baja |
| `ASK-008` | `run_vegeta.sh` está hardcoded a `RATE="1/s"` mientras el TP, el README y el ADR D11 exigen 50 req/s. ¿El rate intencional es 50 req/s (corregir el script por el equipo) o 1/s es una reducción deliberada de ensayo? | **`[RESUELTO - DIFERIDO]` (2026-10-18):** el rate intencional es **50 req/s**; la corrección queda para la etapa final de benchmarks (prioridad: funcionamiento del sistema). Ver `FIND-007`. | Comparabilidad Vegeta vs referencia del TP (1.500 reqs) | **Alta** (diferida) |
| `ASK-009` | `tests/load/pdfs/Essential-Kanban-Condensed-Spanish.pdf` es idéntico a `heavy.292.pdf` del extractor. ¿Cuál es el documento oficial real que debe ocupar ese lugar? ¿Se pueden verificar los hashes de los 4 PDFs del conjunto? | `FIND-011` / `CON-016`. Afecta la validez de la rotación de 4 documentos. | Validez de los benchmarks de carga | **Alta** |

---

## Registro de Resoluciones — orden de implementación 2026-10-17

> **Nota de nomenclatura:** la orden de implementación recibida rotuló estos puntos como `FIND-005 / ASK-006` (Markdown) y `ASK-007` (healthchecks D8 + Mongo D7). En este registro de auditoría los IDs estables son: Markdown = `ASK-005`; Mongo D7 = `ASK-006`; `.env` = `ASK-007` (sin relación con la orden). Se deja constancia para evitar ambigüedad; los IDs de este documento no se renumeran.

### R-01 — Conversión a Markdown (`FIND-005`, `ASK-005`) — `[RESUELTO E IMPLEMENTADO]`

- **Decisión del equipo:** convertir el contenido del PDF a Markdown estructurado de forma nativa con PyMuPDF (sin librerías externas de ML/OCR), preservando el contrato `{content, page_count}`.
- **Archivos modificados:**
  - `pdf-extractext-extractor/src/pdf_extractext_extractor/domain/extractor.py` (reescrito; helpers `_page_to_markdown`, `_line_properties`, `_base_font_size`, `_heading_level`, `_bullet_content`).
  - `pdf-extractext-extractor/src/pdf_extractext_extractor/extraction.py` (docstring del contrato; sin cambio de campos).
  - `pdf-extractext-extractor/tests/domain/conftest.py` + `tests/domain/test_extractor.py` (3 fixtures + 7 tests).
- **Verificación `[VERIFICADO-PRUEBA]`:** `uv run pytest -q` → `70 passed, 1 xfailed`.
- **Detalle completo:** ver bloque "Implementación Realizada y Verificación" en `audit-findings.md` (`FIND-005`).

### R-02 — Healthchecks D8 y MongoDB D7 (`FIND-006`, `ASK-006`) — `[RESUELTO E IMPLEMENTADO]`

- **Decisión del equipo:**
  - **D8:** conservar la implementación actual de healthchecks (binario `healthprobe` en Go; `python3`/`urllib` en Python) por ser más liviana y con menor superficie de ataque que instalar `curl`; actualizar el ADR para que la documente con precisión.
  - **D7:** alinear la versión de MongoDB a `mongo:8` entre compose, tests de integración y documentación.
- **Archivos modificados:**
  - `pdf-extractext-infrastructure/docs/architecture-decisions.md` → D7 (l.48-52) y D8 (l.53-72) reescritos.
  - `pdf-extractext-persistence/README.md` → `mongo:7.0` → `mongo:8` (l.35, l.112).
  - (El código de tests ya usaba `mongo:8` vía `mongoImage()` en `internal/infra/mongo/client_integration_test.go:27-32`.)
- **Verificación `[VERIFICADO-PRUEBA]`:** `go build ./...` OK; `go vet -tags=integration ./...` OK; `go test ./...` OK (los tests de integración requieren Docker y no se ejecutaron).
- **Detalle completo:** ver bloque "Implementación Realizada y Verificación" en `audit-findings.md` (`FIND-006`).

---

## Registro de Resoluciones — re-verificación 2026-10-18

> Sesión de alineación de la Etapa 1: se contrastaron los documentos de `audit/` contra el estado real del repositorio y se corrigieron las desviaciones documentales detectadas. Todas las modificaciones son de documentación (y una robustez menor de script); no cambian comportamiento del sistema.

### R-03 — Artefactos de carga y contradicciones documentales (`FIND-001`, `FIND-002`, `CON-001`, `CON-002`, `CON-008`, `ASK-001`, `ASK-004`)

- **Hallazgo de la re-verificación:** los 4 PDFs oficiales **están presentes** en `tests/load/pdfs/` y hay **5 corridas registradas** locales en `docs/test-runs/`; los PDFs estaban gitignoreados.
- **Decisión del equipo (revisada):** **versionar los 4 PDFs** para que un clon limpio pueda correr las pruebas (se eliminó la regla `tests/load/pdfs/*.pdf`). Las corridas de `docs/test-runs/` siguen siendo **locales** (no se versionan).
- **Archivos modificados:** `.gitignore` (regla de exclusión eliminada; comentarios actualizados), `README.md` (PDFs ahora versionados + aclaración de corridas locales + nota de perfiles en corrección).
- **Detalle:** `FIND-001`, `FIND-002`. Queda abierto `FIND-011` (uno de los PDFs está duplicado).

### R-04 — Informe técnico con métricas simuladas (`FIND-008`, `CON-012`)

- **Decisión del equipo:** neutralizar las cifras simuladas; no inventar reemplazos.
- **Archivos modificados:** `docs/informe_tecnico.md` → §4 reescrita como "pendiente de corridas válidas" con tablas vacías; se quitó la referencia a los archivos de corrida inexistentes.
- **Detalle:** `FIND-008`.

### R-05 — Deriva del ADR y del README de Infrastructure (`FIND-009`, `FIND-010`, `CON-013`, `CON-014`, `CON-015`)

- **Decisión del equipo:** alinear ADR, `.env.example` y README con la implementación real.
- **Archivos modificados:**
  - `docs/architecture-decisions.md` → D9 (tabla real de límites de los 5 servicios) y D5 (`API_TAG`).
  - `.env.example` → referencia `docs/pending-decisions.md` → `docs/architecture-decisions.md`.
  - `README.md` → "14 checks" → "15 checks".
  - `scripts/record-run.sh` → `mongo_version()` robustecido (evita versión espuria "desconocida").
- **Detalle:** `FIND-009`, `FIND-010`.

### R-06 — READMEs de los servicios desactualizados (`FIND-004`, `CON-003`…`CON-006`)

- **Hallazgo:** los README de `pdf-extractext-api`, `pdf-extractext-extractor` y `pdf-extractext-persistence` describían un estado "bootstrap" que el código ya superó.
- **Decisión del equipo:** actualizarlos al estado real (solo documentación).
- **Archivos modificados (en repos hermanos):**
  - `pdf-extractext-api/README.md` → endpoints reales (`/`, `/extract`, `/upload-pdf`, CRUD `/documents`), variables, errores, estructura, CI; `pdf-extractext-api/.env.example` → comentario de `PERSISTENCE_URL` alineado.
  - `pdf-extractext-extractor/README.md` → contrato real de `POST /extract` (5 campos, Markdown), `/readyz`, estructura.
  - `pdf-extractext-persistence/README.md` → sección de API (CRUD + probes), estado y estructura reales.
- **Pendiente relacionado:** ampliar `pdf-extractext-api/docs/openapi.yaml` (hoy solo `/` y `/upload-pdf`).
- **Detalle:** `FIND-004`.
