# Audit Benchmark — PDF Extractext

Inventario verificado de artefactos de pruebas de carga y referencia externa del TP.
Inspección de solo lectura: `find`, `ls`, `wc`, `sha256sum` (2026-10-17).

---

## 1. Inventario verificado de PDFs de prueba

### 1.1 PDFs presentes en el workspace

| Repo | Ruta | Tamaño (bytes) | SHA-256 | Notas |
|---|---|---|---|---|
| `pdf-extractext-extractor` | `tests/data/heavy.292.pdf` | 8.901.466 | `257f73b908420ac5c78852fb8673beb683a8ca0c05d2e6a82b5e9629f6ad7be8` | Usado por `tests/load/k6_suite.js` y `tests/load/vegeta_target.sh` del repo Extractor. `[VERIFICADO-CÓDIGO]` |

**Total de PDFs en el workspace: 1.** Búsqueda `find … -iname "*.pdf"` (ignorando `.git`) sin otros resultados. `[VERIFICADO-CÓDIGO]`

### 1.2 PDFs oficiales del TP — AUSENTES en disco

Esperados por `pdf-extractext-infrastructure/tests/load/vegeta/run_vegeta.sh:34-39` y `tests/load/spike_tests.js:17-22`:

| # | Nombre esperado | Tamaño | SHA-256 | Estado |
|---|---|---|---|---|
| 1 | `2020-Scrum-Guide-Spanish-Latin-South-American.pdf` | — | — | **AUSENTE** `[VERIFICADO-CÓDIGO]` |
| 2 | `Essential-Kanban-Condensed-Spanish.pdf` | — | — | **AUSENTE** `[VERIFICADO-CÓDIGO]` |
| 3 | `Filosofia Lean.pdf` | — | — | **AUSENTE** `[VERIFICADO-CÓDIGO]` |
| 4 | `scrum_manager_historias_usuario.pdf` | — | — | **AUSENTE** `[VERIFICADO-CÓDIGO]` |

- Ubicación esperada: `pdf-extractext-infrastructure/tests/load/pdfs/`.
- Motivo: excluidos por `.gitignore:18` (`tests/load/pdfs/*.pdf`); ver `FIND-001`/`FIND-002` y `ASK-001`.
- La ruta del enunciado `tests/stress/pdfs` **no existe** en ningún repo (`FIND-001`, `ASK-002`).

### 1.3 Fixtures generables (no versionados, regenerables)

Generados por `pdf-extractext-infrastructure/tests/load/pdfs/generate_fixtures.sh` (determinísticos, se crean on-the-fly con `make load-k6`/`make load-vegeta` o ejecutando el script). Consumidos por `k6-spike.js:22`:

| Nombre | Páginas | Estado en disco |
|---|---|---|
| `fixture-1p.pdf` | 1 | AUSENTE (regenerable) |
| `fixture-3p.pdf` | 3 | AUSENTE (regenerable) |
| `fixture-8p.pdf` | 8 | AUSENTE (regenerable) |
| `fixture-20p.pdf` | 20 | AUSENTE (regenerable) |

`[VERIFICADO-CÓDIGO]` — el script existe y construye PDFs válidos con xref real; los `.pdf` resultantes no están en disco (tampoco serían versionados).

---

## 2. Scripts de benchmark — ubicación verificada

### 2.1 Infrastructure (`pdf-extractext-infrastructure`) — suite del sistema completo

| Herramienta | Ruta | Perfil implementado | Target por defecto | Invocado por |
|---|---|---|---|---|
| k6 (spike 100 VUs) | `tests/load/k6-spike.js` | 10s→100 VUs, 20s a 100, 10s→0 (40s total); métricas p50/p90/p95; `insecureSkipTLSVerify`; rota 4 fixtures `fixture-*.pdf` | `https://pdf-extractext.localhost/extract` | **NINGUNO** (`FIND-003`) |
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

Estas cifras **provienen directamente del enunciado de la cátedra** (información externa a los repos). No fueron reproducidas ni verificadas en esta auditoría: `docs/test-runs/` del repo Infrastructure solo contiene `TEMPLATE.md` y no hay corridas registradas. Se registran aquí como línea base para contrastar cuando los PDFs oficiales estén disponibles (`ASK-001`) y se ejecuten las corridas en las Etapas 3/4.

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

Coherencia estática observada: el perfil coincide exactamente con las stages de `k6-spike.js` (no con `spike_tests.js`, que usa 1 VU) → `FIND-003`.

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
| 4 PDFs oficiales en `tests/load/pdfs/` | **FALTAN** | `FIND-001` / `ASK-001` |
| `pdf-extractext.localhost` resuelve a 127.0.0.1 | No verificado | README requiere ajuste manual en WSL/glibc |
| Suite de registro (`record-run.sh`) | Presente | `scripts/record-run.sh`; `docs/test-runs/` vacío salvo `TEMPLATE.md` |
| Réplicas de Extraction configurables 1–5 | Verificado (código) | `Makefile:check` valida el rango antes de `make up` |

---

## 5. Restricciones aplicadas en la generación de este documento

- No se ejecutaron benchmarks, servicios ni cargas (restricción 6 del enunciado de auditoría).
- No se modificaron scripts, Dockerfiles, compose ni datos de prueba.
- Hashes calculados con `sha256sum` sobre el único PDF presente; tamaños con `ls -la`/`wc -c`.
