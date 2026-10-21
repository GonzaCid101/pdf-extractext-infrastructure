# Audit Benchmark — PDF Extractext

Inventario verificado de artefactos de pruebas de carga y referencia externa del TP.
Inspección de solo lectura: `find`, `ls`, `wc`, `sha256sum` (2026-10-17).

---

## 1. Inventario verificado de PDFs de prueba

### 1.1 PDFs presentes en el workspace

| Repo | Ruta | Tamaño (bytes) | SHA-256 | Notas |
|---|---|---|---|---|
| `pdf-extractext-extractor` | `tests/data/heavy.292.pdf` | 8.901.466 | `257f73b908420ac5c78852fb8673beb683a8ca0c05d2e6a82b5e9629f6ad7be8` | Idéntico a `Essential-Kanban-Condensed-Spanish.pdf` (`FIND-011`); eliminado 2026-10-21 con la suite del Extractor. `[VERIFICADO-CÓDIGO]` |

**Total de PDFs en el workspace (2026-10-18): 5** = `heavy.292.pdf` (extractor) + los 4 PDFs oficiales en `tests/load/pdfs/` (ver §1.2). Nota: `Essential-Kanban-Condensed-Spanish.pdf` es una copia exacta de `heavy.292.pdf`. `[VERIFICADO-CÓDIGO]`

### 1.2 PDFs oficiales del TP — presentes y versionados

Re-verificado el 2026-10-18: los 4 PDFs que esperan `run_vegeta.sh:34-43` y `spike_tests.js:17-22` están presentes en `pdf-extractext-infrastructure/tests/load/pdfs/` y **se versionan** en el repo (se eliminó la regla `tests/load/pdfs/*.pdf` de `.gitignore`).

| # | Nombre | Tamaño (bytes) | SHA-256 |
|---|---|---|---|
| 1 | `2020-Scrum-Guide-Spanish-Latin-South-American.pdf` | 319.343 | `6bbff3f361e52016cbb75a72671f1b31b5e043fdc1cc3f022f1b15a32795a256` |
| 2 | `Essential-Kanban-Condensed-Spanish.pdf` | 8.901.466 | `257f73b908420ac5c78852fb8673beb683a8ca0c05d2e6a82b5e9629f6ad7be8` |
| 3 | `Filosofia Lean.pdf` | 668.142 | `c77b55bd68477ecc0d96074ea4606bffe5802a1c8a241a725f6eb358be17ce40` |
| 4 | `scrum_manager_historias_usuario.pdf` | 3.830.899 | `30efd6fcd0c022665676edcf164feb28e6b43dcce53ab9738550b99d70f5fd84` |

- **Hallazgo (`FIND-011`, resuelto 2026-10-21):** `Essential-Kanban-Condensed-Spanish.pdf` era **byte a byte idéntico** a `pdf-extractext-extractor/tests/data/heavy.292.pdf` (mismo SHA-256 y tamaño): el duplicado estaba en el Extractor, no en este corpus. Se eliminó `heavy.292.pdf` con la suite de carga del Extractor; los 4 PDFs de Infrastructure tienen hashes únicos y son el corpus oficial.
- Ubicación: `pdf-extractext-infrastructure/tests/load/pdfs/` (versionados).
- La ruta del enunciado `tests/stress/pdfs` **no existe** en ningún repo (`FIND-001`, `ASK-002`).

#### Re-verificación Etapa 4 (2026-10-20) — características de extracción

Medición de solo lectura del corpus con `pdfinfo`, `pdfimages -list`, `pdftotext` y `sha256sum` (sin ejecutar cargas). **Reinterpretación de `FIND-011`:** "Essential-Kanban" tiene **90 páginas** (no 292), coincide con `heavy.292.pdf` y con la cifra de 90 páginas que la Etapa 3A registró para `heavy.292` (§6 item 29). El corpus contiene solo **dos documentos de texto pesado** (Kanban 8,5 MB y Scrum Manager 3,7 MB); sus 4 archivos tienen **hashes únicos entre sí** (la coincidencia era con `heavy.292.pdf` del Extractor, eliminado el 2026-10-21).

| # | Nombre | Páginas | Páginas con texto | Caracteres de texto | Imágenes | Tipo |
|---|---|---|---|---|---|---|
| 1 | `2020-Scrum-Guide-Spanish-Latin-South-American.pdf` | 16 | 16 | 35.345 | 0 | texto nativo |
| 2 | `Essential-Kanban-Condensed-Spanish.pdf` | 90 | 90 | 125.211 | 91 | texto + 91 imágenes |
| 3 | `Filosofia Lean.pdf` | 42 | 42 | 59.089 | 21 | texto + 21 imágenes |
| 4 | `scrum_manager_historias_usuario.pdf` | 62 | 62 | 91.228 | 40 | texto + 40 imágenes |

- **Ningún PDF es escaneado:** los 4 tienen texto nativo (`pdftotext` extrae >35 KB en todos) y **ninguno está cifrado** (`pdfinfo`: `Encrypted: no`). El corpus no ejercita el camino de imágenes escaneadas (OCR inexistente en el extractor).
- **Carga dispar**: el Kanban (8,5 MB, 90 páginas) es ~28× el Scrum Guide (319 KB, 16 páginas) y ~13× el resto. La rotación aleatoria de k6 y el round-robin de Vegeta reparten peticiones con coste muy desigual → los percentiles mezclan el PDF barato con el caro.
- **Carga por script:** `spike_tests.js:24` abre los 4 PDFs **enteros en memoria** en la fase `init` (`open(path,'b')`) y los reutiliza; `run_vegeta.sh:42-61` genera **4 cuerpos multipart completos** (uno por PDF) más los targets. Vegeta, además, recorre esos 4 targets en round-robin (`spike_tests.js:27`; `run_vegeta.sh:42`).

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
| k6 (ejecutable) | `tests/load/spike_tests.js` | stages 10s→**1 VU**, 20s a 1, 10s→0; checkea 200 + `{content, page_count}`; rota los 4 PDFs oficiales | `https://pdf-extractext.localhost/extract` | `tests/load/run_k6.sh:21` ← `make load-k6`. **Etapa 4: `run_k6.sh` usa `--summary-export` (retirado en k6 v2.x) → no se genera resumen y las métricas quedan a 0** → `FIND-049` |
| k6 runner | `tests/load/run_k6.sh` | Exporta resumen, calcula p50/p90/p95/throughput/éxito y registra vía `record-run.sh` (o `RECORD=0`) | — | `Makefile:57-58` |
| Vegeta | `tests/load/vegeta/run_vegeta.sh` | **Documenta** 50 req/s × 30s, timeout 30s, `-insecure`; cuerpos multipart precompilados; rota los 4 PDFs oficiales. **Implementación real: `RATE="1/s"`** (≈30 reqs en 30s, no 1.500) → `FIND-007`. **Etapa 4: los targets se emiten en formato `http` sin `@archivo`, que Vegeta v12 rechaza de plano** → `FIND-048` | `https://pdf-extractext.localhost/extract` | `Makefile:60-61` (`make load-vegeta`) |
| Mock API (ensayos) | `tests/load/mock_api.py` | Servidor simulado para `RECORD=0` | — | manual |
| Registro de corridas | `scripts/record-run.sh` + `docs/test-runs/TEMPLATE.md` | Genera `docs/test-runs/<fechaUTC>-<tool>.md` con config real del stack | — | `run_k6.sh`, `run_vegeta.sh`, `make record-run` |

`[VERIFICADO-CÓDIGO]` — todos los archivos listados existen y fueron leídos.

### 2.2 Extractor (`pdf-extractext-extractor`) — suite del servicio aislado (eliminada 2026-10-21)

| Herramienta | Ruta | Perfil | Target | PDF usado |
|---|---|---|---|---|
| k6 | `tests/load/k6_suite.js` | spike 10s→100, 30s, 5s→0 + carga constante 25 req/s × 60s (startTime 50s); thresholds p99<2s, errores no-503 <1% | `http://localhost:8090/extract` (Host `extraction.pdf-extractext.localhost`) | `tests/data/heavy.292.pdf` (8,5 MB) |
| Vegeta | `tests/load/vegeta_target.sh` | Genera body multipart + target file (el ataque se lanza aparte) | `http://localhost:8090/extract` | `tests/data/heavy.292.pdf` |
| Perfilado | `tests/load/profile.sh` | — | — | — |

`[VERIFICADO-CÓDIGO]`

**Duplicidad (resuelta 2026-10-21):** solo queda la suite de Infrastructure; la del Extractor fue eliminada. Canónica del TP: `ASK-003` / `FIND-003`.

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
| 4 PDFs oficiales en `tests/load/pdfs/` | **Presentes, versionados y únicos** | `FIND-001`; `FIND-011` resuelto 2026-10-21 (el duplicado era `heavy.292.pdf` en el Extractor, ya eliminado) |
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

## 6. Auditoría Etapa 4 — Validez metodológica de las pruebas de carga (Área E) — 2026-10-20

Inspección de **solo lectura** de los scripts y del corpus (restricciones 6 y 8). Se ejecutaron **dos validaciones acotadas que no requieren el stack ni generan carga sobre los servicios del proyecto**: (a) `k6 inspect` del escenario real (no ejecuta VUs ni red), y (b) una reproducción de los targets de Vegeta contra un **servidor stub local de un solo uso en `/tmp/opencode/`** (ningún contenedor del proyecto fue tocado; el stub ya fue detenido). No se lanzó el spike de 100 VUs ni el ataque de 50 req/s. El stack está **sin levantar** en este host (`docker compose ps` vacío); `k6` sí está instalado, `vegeta` **no** (se instaló una copia de solo-lectura en `~/go/bin` para validar sintaxis, ver `FIND-048`).

### 6.1 Corpus de PDFs (`tests/load/pdfs`) vs consigna `tests/stress/pdfs`

| Aspecto | Consigna | Implementación actual | Veredicto |
|---|---|---|---|
| Ruta | `tests/stress/pdfs/` | `tests/load/pdfs/` (versionados) | **Desviación** (`FIND-001`, ya registrada). Repos: existen `tests/load/pdfs` (Infrastructure) y `tests/data/heavy.292.pdf` (Extractor); **`tests/stress/pdfs` no existe** en ningún repo. |
| Nº de PDFs | 4 | 4 archivos / **3 hashes únicos** | **Parcial**: `Essential-Kanban…` ≡ `heavy.292.pdf` (`FIND-011`). |
| Disparidad de coste | — | 319 KB→8,9 MB; 16→90 páginas; 0→91 imágenes | **Sesgo de corpus**: la rotación cubre documentos ~28× más caros que otros. |
| Tipo | (no se exige) | Todos texto nativo, ninguno cifrado | OK para `/extract`; no cubre escaneados. |

Cómo cargan los scripts: k6 abre los 4 PDFs en `init` y rota **al azar** (`spike_tests.js:24,27`); Vegeta precompila 4 cuerpos y rota **round-robin** por orden (`run_vegeta.sh:42`).

### 6.2 k6 — Prueba Spike (modelo cerrado): Consigna vs implementación

| Parámetro | Consigna (enunciado) | `tests/load/spike_tests.js` | `run_k6.sh` invocación (`make load-k6`) |
|---|---|---|---|
| Etapa 1 de rampa | 0→100 VUs en 10s (`target: 100`) | **`target: 1`** (`:9`) | ídem |
| Meseta | 100 VUs durante 20s | 1 VU 20s (`:10`) | ídem |
| Etapa de bajada | →0 VUs en 10s | →0 en 10s (`:11`) | ídem |
| `sleep()` entre iteraciones | — (no exigido; determina el modelo) | **NO hay `sleep`** (`:26-49`): dispara la siguiente petición en cuanto responde | ídem |
| Modelo de carga | Cerrado (VUs fijas) | `ramping-vus` (cerrado) | — |
| Request a `/extract` | POST multipart | **multipart/form-data**, campo `file`, PDF rotado (`:30-34`) | — |
| Validaciones | (no se exige) | `check` 200 **+** JSON con `content` no vacío y `page_count` entero >0 (`:36-47`) | — |
| Salida de métricas | — | — | **`--summary-export` retirado en k6 v2.x** → resumen no generado, p50/p90/p95/throughput/success = 0 (`FIND-049`) |

**Sobre el modelo cerrado y el `sleep`:** al no haber `sleep`, cada VU envía una petición nueva inmediatamente al recibir la anterior. El throughput máximo de un VU = 1 / latencia de respuesta; con 100 VUs el throughput del sistema queda **acoplado a la latencia** (si el sistema se degrada, baja el throughput y sube la latencia; el sistema no puede "sobrecargarse" más allá de la capacidad que el cierre por VUs permite). Es un modelo de **cierre legítimo** de la consigna, pero **no reproduce** las 25 req/s de llegada de la referencia del TP (`[DOCUMENTADO-NO-VERIFICADO]`), depende del tiempo de respuesta y hace que el escenario sea **no comparable** con la corrida de la cátedra si esta se hizo con llegadas abiertas.

### 6.3 Vegeta — Carga abierta (50 req/s): Consigna vs implementación

| Parámetro | Consigna (enunciado) | `tests/load/vegeta/run_vegeta.sh` |
|---|---|---|
| Tasa | `-rate=50` (50 req/s) | **`RATE="1/s"`** (`:15`) → ≈30 reqs en 30s, no 1.500 → `FIND-007` |
| Duración | `-duration=30s` (1.500 reqs) | `DURATION="30s"` (`:16`) |
| Timeout cliente | `-timeout=30s` | `TIMEOUT="30s"` (`:17`) ✅ |
| Rotación | 4 PDFs | 4 targets, round-robin (`:42-61`) ✅ |
| Formato de targets | — | **`http` por defecto, sin `@archivo`; el body se embebe tras una línea en blanco** (`:53-59`) |
| Aceptación por Vegeta v12 | — | **FALLA:** `bad target: --pdf-extractext-vegeta-boundary` (exit 1, **0 peticiones enviadas**) → `FIND-048` |
| `-insecure` | (necesario por TLS mkcert) | presente (`:65`) ✅ |
| Multipart bien formado | — | Sí: boundary, `Content-Disposition: file`, `Content-Type: application/pdf`, `Content-Length` exacto y body válido (verificado contra el stub) |

**Causa raíz de `FIND-048` (verificada, no inferida):** el parser de targets `http` de Vegeta (`lib/targets.go`, `NewHTTPTargeter`) lee el body con un `bufio.Scanner` **línea a línea** y **solo** acepta el body externo vía `@/ruta` (o `-body`); la primera línea **no vacía** debe empezar con un método HTTP en mayúsculas. Al embeber el multipart tras una línea en blanco, la primera línea de contenido (`--pdf-extractext-vegeta-boundary` con CRLF) **no** empieza por mayúsculas + espacio → `bad target`. En Vegeta ≥ 12.8 el target se lee en modo JSON (`NewJSONTargeter`: `{method,url,header,body}` con `body` en base64), no HTTP; el script se escribió asumiendo una versión anterior. **Evidencia:** reproducción del comando literal del repo contra el stub → mismo error; reproducción equivalente en `-format=json` (body base64) → **6/6 peticiones 200**, multipart correcto, `Content-Length` == bytes reales, rotación de 4 cuerpos confirmada.

### 6.4 Sesgos y amenazas a la validez de las métricas (interacción con API/Extraction/Persistence)

| # | Sesgo / amenaza | Base y evidencia | Efecto sobre las métricas |
|---|---|---|---|
| B1 | **Vegeta aborta antes de medir** | `FIND-048`: `bad target`, exit 1, 0 peticiones | Ninguna métrica de Vegeta es hoy válida; el benchmark de carga abierta **no corre**. |
| B2 | **k6 no exporta resumen** | `FIND-049`: `--summary-export` retirado en v2.x | p50/p90/p95/throughput/success = 0 aunque el ataque ocurra. Solo quedan los checks en consola. |
| B3 | **Perfil k6 ≠ consigna** | `spike_tests.js:9` `target: 1` vs 100 VUs | Throughput/latencias no son las del spike del TP. |
| B4 | **Perfil Vegeta ≠ consigna** | `run_vegeta.sh:15` `RATE="1/s"` vs 50/s | No reproduce 1.500 reqs ni el 16,65 req/s de referencia. |
| B5 | **Corpus con hash duplicado + disparidad** | `FIND-011`; §6.1 | El coste por request varía ×28; los percentiles mezclan barato/caro y el "4 PDFs" es en realidad 3. |
| B6 | **Sin caché/dedupe/rate-limit en `/extract`** | `extract.go:22-56` (stateless, sin caché); `INT-01`. Los 409/`ErrConflict` pertenecen a `/upload-pdf`→Slices, **que las suites de carga no atacan** | **No** aparecen 409/400/422 espurios en estas corridas: cada request extrae de verdad. **El sesgo 409 es teórico aquí** (solo aplicaría si se atacara `/upload-pdf`). |
| B7 | **Estado residual en Mongo** | Mongo solo lo toca Persistence; las suites usan `/extract` (stateless). Las corridas de k6/Vegeta **no escriben** documentos | La reproducibilidad de *estas* corridas no depende de Mongo. Si se hiciera una variante contra `/upload-pdf`, sí habría estado acumulado (`INT-03`, índice `checksum_1`). |
| B8 | **Sin instrumentación de infraestructura** | Los scripts solo guardan la salida del cliente (k6/Vegeta). No hay `docker stats`, métricas por contenedor, reinicios/OOMKilled ni distribución entre réplicas | Imposible atribuir latencias a CPU/memoria/replicación ni validar `HYP-07`/`FIND-047`/`FIND-035` con lo que hoy capturan los scripts. |
| B9 | **`mock_api.py` no reproducible** | `FIND-046`: `page_count` 0, errores legacy, path duro `/tmp` | El ensayo `RECORD=0` falla el check de contrato de k6 y no valida problem+json. |

**Conclusión de validez:** con los scripts **tal cual**, la corrida del TP **no se reproduce**: Vegeta no envía nada (B1) y k6 mide un perfil de 1 VU del que además no extrae estadísticas (B2+B3). Las cifras de la cátedra siguen siendo `[DOCUMENTADO-NO-VERIFICADO]`. Corregidos `FIND-003` (k6 a 100 VUs), `FIND-007` (Vegeta 50/s), `FIND-048` (formato de targets), `FIND-049` (resumen k6) y `FIND-011` (corpus), el diseño de los escenarios (multipart correcto, timeout 30s, rotación) sí es apto para producir mediciones comparables.

### 6.5 Instrumentación y observabilidad necesaria (huecos)

| Necesidad | Estado en los scripts | Herramienta sugerida (solo lectura) |
|---|---|---|
| CPU/memoria y OOMKilled por contenedor | Ausente | `docker stats --no-stream` en bucle + `docker inspect -f '{{.State.OOMKilled}} {{.RestartCount}}'` |
| Distribución de peticiones entre réplicas de Extraction | Ausente | `docker logs` de cada réplica (contar `EXTRACT` por `X-Request-ID`) o `k6` con tag por Host |
| Distribución de status (503 vs 502/timeout) | Parcial (k6 check, no exportado) | `vegeta report -type=json`/`encode`; en k6, `handleSummary` |
| Estado de healthcheck bajo carga | Ausente | `docker inspect -f '{{.State.Health.Status}}'` en bucle (`HYP-08`) |
| RSS de la API bajo 100 VUs (`FIND-047`) | Ausente | `docker stats` de `api` durante el spike |

### 6.6 Protocolo de Ejecución Reproducible y Limpio (para el equipo)

Pensado para que dos corridas consecutivas sean comparables. Los pasos que **modifican el entorno** (limpiar Mongo, recrear el stack, lanzar cargas) requieren autorización explícita (restricción 6). **Estado 2026-10-21:** las correcciones de Fase 1 **ya están aplicadas**; la corrida real queda pendiente de validación.

**Fase 0 — Pre-vuelo (solo lectura):**
```bash
cd pdf-extractext-infrastructure
command -v k6 vegeta jq mkcert      # vegeta en PATH (/usr/local/bin) o $HOME/go/bin
docker compose ps                    # stack arriba y healthy; Traefik con red services (FIND-045)
docker inspect -f '{{.State.Health.Status}} {{.State.OOMKilled}} {{.RestartCount}}' \
  $(docker compose ps -q)
```

**Fase 1 — Correcciones previas obligatorias** (APLICADAS 2026-10-21; ver §6.7):
1. `FIND-048`: `run_vegeta.sh` emite targets en `-format=json` (body base64 vía `--rawfile`). ✔
2. `FIND-049`: `spike_tests.js` con `handleSummary()`; `run_k6.sh` parsea el formato v2.x. ✔
3. `FIND-003`: `spike_tests.js` con stages `10s→100, 20s→100, 10s→0` (parametrizable `TARGET_VUS`). ✔
4. `FIND-007`: `RATE="${RATE:-50/s}"` (1.500 reqs). ✔
5. `FIND-011`: el `Essential-Kanban…` duplicado **sigue** (pendiente de decisión; documentar corpus de 3 hashes).

**Fase 2 — Estado limpio (requiere autorización):**
```bash
EXTRACTION_REPLICAS=1 make up        # fijar la topología a medir (1 vs 5 réplicas, documentada)
# Dejar Mongo sin residuos SOLO si se medirá /upload-pdf (estas suites usan /extract, stateless):
#   mongosh --eval "db.uploaded_documents.deleteMany({})"   # confirmar nombre de la colección primero
# Esperar a que todos los healthchecks estén 'healthy' antes de empezar a medir.
```

**Fase 3 — Monitoreo en paralelo (otra terminal, durante toda la corrida):**
```bash
# Muestreo cada 1 s de CPU/mem por contenedor
while :; do docker stats --no-stream --format \
  '{{.Name}} {{.CPUPerc}} {{.MemUsage}} {{.MemPerc}}'; sleep 1; done | tee /tmp/stats-$(date -u +%s).log
# Healthcheck/OOM/restart al final
docker inspect -f '{{.Name}} oom={{.State.OOMKilled}} restarts={{.RestartCount}} health={{if .State.Health}}{{.State.Health.Status}}{{end}}' \
  $(docker compose ps -q) | tee /tmp/inspect-end.log
```

**Fase 4 — Ataques y captura (con los scripts ya corregidos):**
```bash
TARGET_VUS=100 RECORD=1 bash tests/load/run_k6.sh 2>&1 | tee /tmp/k6-$(date -u +%s).log
KEEP_RESULTS=1 RECORD=1 bash tests/load/vegeta/run_vegeta.sh 2>&1 | tee /tmp/vegeta-$(date -u +%s).log
```

**Fase 5 — Cierre y registro:**
- Anotar en `docs/test-runs/<fecha>-<tool>.md`: réplicas, límites, versión de k6/Vegeta, el corpus efectivo (3 hashes), y las tasas reales.
- Adjuntar el `docker stats` e `inspect` de Fase 3 como evidencia de `HYP-07`/`FIND-047`.
- Comparar la **distribución de status** (200 vs 503 vs 502/timeout) para separar backpressure real (`HYP-04`/`HYP-09`) de timeouts de cliente.

### 6.7 Sesión de correcciones y ejecución — 2026-10-21

Correcciones aplicadas a los 3 scripts de carga de Infrastructure (autorizadas por el equipo). Validación contra el **mock oficial del propio repo** (`tests/load/mock_api.py`, que valida multipart y SHA256 de los 4 PDFs) y, complementariamente, un stub local de un solo uso en `/tmp/opencode/bt/` (ambos ya detenidos; ningún contenedor del proyecto tocado, ninguna carga contra los servicios del proyecto).

| Archivo | Cambio | Validación |
|---|---|---|
| `tests/load/spike_tests.js` | Stages `10s→TARGET_VUS(100), 20s→100, 10s→0`; `sleep(0.5)`; `summaryTrendStats` con p50/p90/p95/p99; `handleSummary()` → `K6_SUMMARY_PATH`; resumen de consola; `BASE_URL` parametrizable | `k6 inspect` → `target: 100` (y `10` con `-e TARGET_VUS=10`); corrida contra mock → 8 reqs, `extract_ok` 100 %, p50/p90/p95 no-cero, JSON escrito |
| `tests/load/run_k6.sh` | Quitado `--summary-export`; parsea `.metrics.*.values.*` (v2.x); `TARGET_VUS` override; **`BASE_URL` derivado de `TARGET_URL` (`FIND-053`)**; muestra p50/p90/p95 + total/fallo | `bash -n` OK; contra mock → 8 reqs al mock, `extract_ok` 100 % (antes: iba al dominio por defecto) |
| `tests/load/vegeta/run_vegeta.sh` | `RATE=${RATE:-50/s}`, `DURATION/TIMEOUT` override; targets `-format=json` con body base64 (`--rawfile`); encuentra `vegeta` en PATH o `$HOME/go/bin`; `KEEP_RESULTS` corregido | `bash -n` OK; contra mock → 30 reqs a 10/s y 150 a 50/s, `bad:0`/`no_file:0`; 4 tamaños de PDF distintos (round-robin) |
| `tests/load/mock_api.py` | `PAGES` con los conteos reales (16/90/42/62) en vez de `0` (`FIND-054`) | Antes: `extract_ok` 0 %; después: `extract_ok` 100 % |

**Chequeos negativos:** `RECORD=1` sin stack → mensaje claro y exit 1 (ambos runners); destino caído en `RECORD=0` → Vegeta reporta `éxito 0 %` sin abortar; `run_k6.sh` propaga el código de salida de k6.

**Corrida real (pendiente):** los benchmarks sobre el stack **no se ejecutaron**; `HYP-07`, `HYP-08`, `FIND-047` y la comparación 1 vs 5 réplicas siguen **sin medición**.

> **Nota de alcance:** las validaciones prueban la *corrección de los scripts* (perfil, formato de targets, extracción de métricas, enrutado a destino), no el *rendimiento del sistema*. Ninguna cifra de las tablas de `docs/informe_tecnico.md` §4 proviene de estas corridas contra mock.

---

## 7. Restricciones aplicadas en la generación de este documento

- No se ejecutaron benchmarks, servicios ni cargas (restricción 6 del enunciado de auditoría).
- No se modificaron scripts, Dockerfiles, compose ni datos de prueba.
- Hashes calculados con `sha256sum` sobre el único PDF presente; tamaños con `ls -la`/`wc -c`.
- §5 es análisis estático del código (fasthttp, clientes HTTP, driver Mongo); no son mediciones.
- §5.5 (Etapa 3C) cruza compose/configs con las suites ejecutadas; la RSS/estabilidad real queda pendiente de Etapa 4 (`FIND-045`, `FIND-047`).
- §6 (Etapa 4, 2026-10-20): solo lectura sobre scripts/corpus. **No se ejecutó** el spike de 100 VUs ni el ataque de 50 req/s (restricción 6). Validaciones acotadas: `k6 inspect` (sin VUs ni red) y reproducción de targets de Vegeta contra un **stub local de un solo uso en `/tmp/opencode/`** (detenido; ningún contenedor del proyecto tocado). `vegeta` se instaló en `~/go/bin` solo para validar sintaxis; no se modificó ningún archivo del proyecto (los 4 repos quedan con `git status` limpio salvo `audit/`).
- §6.7 (Etapa 4, 2026-10-21): correcciones de scripts **validadas** contra el mock oficial `tests/load/mock_api.py` y un stub local, ambos detenidos. **No** se levantó el stack ni se lanzó carga contra servicios del proyecto. No se modificó `MONGO_IMAGE`, compose, límites ni perfiles; los cambios se limitan a `tests/load/` (scripts + mock) y `README.md`/`audit/`/`docs/`.
