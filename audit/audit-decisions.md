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
| `DEC-09` | D9 | Límites CPU/mem por instancia; réplicas Extraction 1–5 | Compose: límites en los 5 servicios; `Makefile:22-25` valida rango 1–5 | `[VERIFICADO-CÓDIGO]` |
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
| `CON-001` | README de Infrastructure: "PDFs oficiales (tests/load/pdfs/): los 4 del profesor. **Sin** generate_fixtures.sh" | `README.md:86-87` | Realidad: solo existe `generate_fixtures.sh` en esa carpeta; los 4 PDFs no están | `FIND-002` | Abierta |
| `CON-002` | `.gitignore` comenta que los PDFs "ya están copiados en el repositorio" pero los ignora con `tests/load/pdfs/*.pdf` | `.gitignore:15-18` | Realidad: 0 PDFs en el repo | `FIND-002` | Abierta |
| `CON-003` | README de API describe bootstrap sin orquestación ni persistencia | `README.md:78-86, 134-150` | `cmd/api/main.go:32-40` (registra `/extract`, `/upload-pdf`, CRUD `/documents`) | `FIND-004` | Abierta |
| `CON-004` | README de Extraction: "solo recepción", respuesta `{filename, size}` | `README.md:3, 36-37` | `extraction.py:10-15` y `domain/extractor.py` (extracción real con PyMuPDF) | `FIND-004` | Abierta |
| `CON-005` | README de Persistence: "CRUD en etapas posteriores" | `README.md:5` | `internal/api/router.go:26-30` (CRUD completo) | `FIND-004` | Abierta |
| `CON-006` | README de API: "Esta API todavía no está declarada en ese compose" | `README.md:26-27` | Infrastructure `docker-compose.yml:28-66` define el servicio `api` (D15 resuelta) | `FIND-004` | Abierta |
| `CON-007` | README de Infrastructure documenta `make load-k6` como spike a 100 VUs; el script ejecutado usa 1 VU | `README.md:75, 81-83` | `run_k6.sh:21` → `spike_tests.js:9-11` (`target: 1`) | `FIND-003` | Abierta |
| `CON-008` | Enunciado de la cátedra: `tests/stress/pdfs`; repos: `tests/load/pdfs` (y vacío de PDFs) | Enunciado TP | Filesystem de los 4 repos | `FIND-001` | Abierta (`ASK-002`) |
| `CON-009` | ADR D8 describe healthchecks con `curl` + CMD-SHELL; implementación real usa binario `/healthprobe` y `python3 -c urllib` | `architecture-decisions.md:55` | `docker-compose.yml:45-48, 93-98, 121-126` | `FIND-006` | **Resuelta** (D8 reescrito) |
| `CON-010` | Enunciado pide `content` convertido a Markdown; el código extrae texto plano y ningún repo contiene código Markdown | Enunciado TP | `domain/extractor.py:35`; grep `markdown` = 0 resultados | `FIND-005` | **Resuelta** (`ASK-005`; Markdown implementado) |
| `CON-011` | `run_vegeta.sh`, README y ADR D11 documentan "50 req/s × 30s"; el script está hardcoded a `RATE="1/s"` (~30 reqs en 30s, no 1.500) | `run_vegeta.sh:2,21`, `README.md:76`, `architecture-decisions.md:71` | `run_vegeta.sh:21,71` (`RATE="1/s"`, `-rate="$RATE"`) | `FIND-007` | Abierta (`ASK-008`) |

---

## Preguntas para el equipo (`ASK-XX`)

| ID | Pregunta | Contexto | Bloquea | Prioridad |
|---|---|---|---|---|
| `ASK-001` | ¿Pueden copiar los 4 PDFs oficiales (`2020-Scrum-Guide-Spanish-Latin-South-American.pdf`, `Essential-Kanban-Condensed-Spanish.pdf`, `Filosofia Lean.pdf`, `scrum_manager_historias_usuario.pdf`) a `tests/load/pdfs/` del repo Infrastructure? | Sin ellos no se pueden ejecutar `make load-vegeta` ni `spike_tests.js` (k6). No bloquean Etapas 2, 3A, 3B, 3C ni 4 (auditoría estática). | Benchmarks reales (Etapa 3/4) | **Alta** |
| `ASK-002` | ¿La ruta del enunciado `tests/stress/pdfs` designa el mismo conjunto que `tests/load/pdfs` del repo, o existe otro repositorio/carpetas no clonados en este workspace? | Ningún repo contiene `tests/stress/`; el workspace solo tiene los 4 repos clonados. | Clarar alcance del conjunto oficial | **Alta** |
| `ASK-003` | ¿Cuál es el script k6 canónico del TP: `k6-spike.js` (100 VUs, usa fixtures generados `fixture-*.pdf`) o `spike_tests.js` (1 VU, usa los 4 PDFs oficiales)? `make load-k6` hoy ejecuta el segundo. | `FIND-003`. La auditoría no puede asumir cuál refleja la intención del equipo ni modificar scripts. | Comparabilidad de resultados k6 con la referencia | **Alta** |
| `ASK-004` | ¿Dónde están registradas las corridas que produjeron las cifras de referencia (1.037 reqs / 25,35 req/s k6; 998 exitosas / 501 timeouts Vegeta)? `docs/test-runs/` solo tiene `TEMPLATE.md`. | Las cifras provienen del enunciado de la cátedra; no fueron reproducidas ni verificadas en esta auditoría. | Contraste de benchmarks | Media |
| `ASK-005` | ~~¿"content convertido a Markdown cuando corresponda" exige transformación real o acepta texto plano?~~ | **`[RESUELTO E IMPLEMENTADO]` (2026-10-17).** El equipo decidió implementar conversión real a Markdown nativo en el extractor. Ver "Registro de Resoluciones" abajo. | — | — |
| `ASK-006` | ~~¿Se alinean los tests de integración de Persistence a `mongo:8` (D7) o se mantiene `mongo:7.0`?~~ | **`[RESUELTO E IMPLEMENTADO]` (2026-10-17).** Confirmado `mongo:8` en tests y README; D7/D8 del ADR actualizados. Ver "Registro de Resoluciones" abajo. | — | — |
| `ASK-007` | ¿Es correcto tratar `.env` de Infrastructure como artefacto local no auditado (contiene credenciales dev)? Confirmar si hay algún valor crítico distinto de `.env.example` que debamos conocer. | El `.env` existe en disco pero no fue releído por contención con secretos. | Claridad de entorno | Baja |
| `ASK-008` | `run_vegeta.sh` está hardcoded a `RATE="1/s"` mientras el TP, el README y el ADR D11 exigen 50 req/s. ¿El rate intencional es 50 req/s (corregir el script por el equipo) o 1/s es una reducción deliberada de ensayo? | `FIND-007` / `CON-011`. La auditoría no modifica scripts ni ejecuta cargas. | Comparabilidad Vegeta vs referencia del TP (1.500 reqs) | **Alta** |

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
