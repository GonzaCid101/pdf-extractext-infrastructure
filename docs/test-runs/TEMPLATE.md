# Corrida de carga — {{RUN_ID}}

Generado por `scripts/record-run.sh`. No editar los datos extraídos del entorno
(Configuración del stack); completar únicamente las Observaciones si aplica.

## Contexto

| Campo | Valor |
|---|---|
| Fecha (UTC) | {{FECHA}} |
| Herramienta | {{TOOL}} |
| Descripción / escenario | {{DESC}} |

## Configuración del stack (extraída del entorno)

| Servicio | Réplicas activas | Imagen (tag) | Límite CPU | Límite Mem | Versión |
|---|---|---|---|---|---|
| Extraction | {{EXT_REPLICAS}} | {{EXT_IMAGE}} | {{EXT_CPU}} | {{EXT_MEM}} | — |
| Persistence | {{PER_REPLICAS}} | {{PER_IMAGE}} | {{PER_CPU}} | {{PER_MEM}} | — |
| Traefik | {{TRA_REPLICAS}} | {{TRA_IMAGE}} | {{TRA_CPU}} | {{TRA_MEM}} | {{TRA_VERSION}} |
| MongoDB | {{MON_REPLICAS}} | {{MON_IMAGE}} | {{MON_CPU}} | {{MON_MEM}} | {{MON_VERSION}} |

## Parámetros de la corrida

- Herramienta: {{TOOL}}
- Target / URL: {{TARGET}}
- Patrón de carga: {{LOAD}}
  (referencia D11: k6 abierto ≥25 req/s; spike 100 VUs; Vegeta 50 req/s × 30 s)

## Resultados

| Métrica | Valor |
|---|---|
| Throughput (req/s) | {{THROUGHPUT}} |
| % éxito | {{SUCCESS}} |
| Latencia p50 (ms) | {{P50}} |
| Latencia p90 (ms) | {{P90}} |
| Latencia p95 (ms) | {{P95}} |

## Observaciones

- TODO: comentarios de la corrida (anomalías, saturación, 503/429, notas).
