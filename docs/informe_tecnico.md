# Informe Técnico - Proyecto Extracción PDF

## 1. Arquitectura del Sistema

Arquitectura de microservicios orquestada con Docker Compose y Traefik como API gateway y balanceador: **Traefik → API → Extraction & Persistence → MongoDB**.

Dos redes aíslan el flujo de datos:

*   **Red `services`**: Traefik, API, Extraction y Persistence; todos se comunican entre sí.
*   **Red `data`**: solo MongoDB y Persistence. Únicamente Persistence tiene acceso directo a la base, lo que reduce la superficie de ataque.

Cada contenedor tiene límite explícito de CPU y memoria (ADR D9), base del escalado horizontal controlado.

## 2. Justificación de Decisiones Arquitectónicas Clave

### Elección de Traefik como API Gateway y Balanceador

*   **Integración nativa con Docker**: auto-descubre los servicios y actualiza rutas y balanceos al iniciar o detener contenedores, sin reconfiguración manual.
*   **Configuración declarativa**: las rutas se definen como labels de Compose, fáciles de versionar.
*   **Gestión de TLS**: simplifica certificados (mkcert en desarrollo) y la redirección HTTP → HTTPS.

### Uso de Entrypoints Internos y Públicos (ADR D3)

*   **Públicos (`:80` y `:443`)**: exponen la API al exterior; `:80` redirige a HTTPS.
*   **Interno (`:8090`)**: solo comunicación entre microservicios (API → Extraction): no se publica al host ni redirige, por lo que las llamadas internas van por HTTP sin sobrecarga de TLS. Es además el punto donde Traefik balancea entre réplicas de Extraction.

### Manejo de Backpressure con HTTP 503 (ADR D10)

Al superar `MAX_CONCURRENCY`, el `AdmissionMiddleware` de Extraction rechaza de inmediato con **503** (fail-fast) y header `Retry-After`. Evita acumular solicitudes que terminarían en timeouts y protege al servicio y a sus dependencias ante saturación.

## 3. Análisis de Cuellos de Botella e Investigación

Con una única réplica de Extraction, un pico de carga con k6 (100 VUs o 25 req/s) llevaba su CPU al 100% sostenido, con:

*   **Latencias altas**: p95/p99 por encima de lo esperado.
*   **Errores HTTP 503**: el `AdmissionMiddleware` rechazaba el exceso.
*   **Timeouts en la API**, que esperaba a un Extractor saturado.

Los logs y las métricas de contenedor confirmaron que la extracción de PDF es intensiva en CPU y que un solo proceso no sostiene la concurrencia. La solución, alineada con el TP, es la **paralelización horizontal**: escalar Extraction a múltiples réplicas y distribuir el tráfico con Traefik.

## 4. Comparativa de Métricas (pendiente de corridas válidas)

> **Estado:** pendiente de corridas válidas. Hoy `tests/load/spike_tests.js`
> corre a 1 VU (no 100) y `run_vegeta.sh` usa `RATE=1/s` (no 50 req/s):
> `FIND-003`, `FIND-007` en `audit/audit-findings.md`. Las corridas de
> `docs/test-runs/` (locales) usan esos perfiles y no son comparables con la
> referencia de la cátedra.

### Escenario Base: 1 Réplica de Extraction

- **Configuración:** `EXTRACTION_REPLICAS=1`, 1 CPU / 1 GB por réplica.

| Métrica | Valor | Unidad | Observaciones |
| :--- | :--- | :--- | :--- |
| Latencia (p95) | — | ms | pendiente de corrida válida |
| Latencia (p99) | — | ms | pendiente de corrida válida |
| Throughput | — | req/s | pendiente de corrida válida |
| Tasa de errores (503) | — | % | pendiente de corrida válida |
| Tasa de errores (500) | — | % | pendiente de corrida válida |

### Escenario Optimizado: 5 Réplicas de Extraction

- **Configuración:** `EXTRACTION_REPLICAS=5`, 1 CPU / 1 GB por réplica.

| Métrica | Valor | Unidad | Observaciones |
| :--- | :--- | :--- | :--- |
| Latencia (p95) | — | ms | pendiente de corrida válida |
| Latencia (p99) | — | ms | pendiente de corrida válida |
| Throughput | — | req/s | pendiente de corrida válida |
| Tasa de errores (503) | — | % | pendiente de corrida válida |
| Tasa de errores (500) | — | % | pendiente de corrida válida |

### Conclusión

La hipótesis a validar es que escalar horizontalmente Extraction de 1 a 5
réplicas reduce la latencia y los rechazos por saturación (503) y aumenta el
throughput, según el análisis cualitativo de la §3. La conclusión numérica
queda pendiente de las corridas de carga válidas.
