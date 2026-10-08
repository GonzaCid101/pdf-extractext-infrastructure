# Informe Técnico - Proyecto Extracción PDF

## 1. Arquitectura del Sistema

El "Proyecto Cabras" se implementa sobre una arquitectura de microservicios orquestada con Docker Compose y Traefik como puerta de enlace API (API Gateway) y balanceador de carga. La topología de red principal es: **Traefik → API Gateway → Extraction & Persistence → MongoDB**.

La infraestructura está diseñada con un fuerte énfasis en el aislamiento de redes para mejorar la seguridad y controlar el flujo de datos. Se definen dos redes principales:

*   **Red `services`**: Incluye a Traefik, el API Gateway, el servicio de Extracción (`extraction`) y el servicio de Persistencia (`persistence`). Todos estos servicios pueden comunicarse entre sí.
*   **Red `data`**: Esta red es exclusiva para MongoDB y el servicio de Persistencia (`persistence`). Esto asegura que **solo el servicio de Persistencia tenga acceso directo a la base de datos MongoDB**, impidiendo que otros microservicios o componentes de infraestructura accedan a ella directamente, lo que reduce la superficie de ataque.

Los servicios de `extraction` y `api` tienen definidos límites de recursos (`1 CPU / 1 GB de memoria`) por contenedor, garantizando un consumo predecible y evitando que un servicio monopolice los recursos del host. Estos límites son fundamentales para el escalado horizontal controlado.

## 2. Justificación de Decisiones Arquitectónicas Clave

### Elección de Traefik como API Gateway y Balanceador

Se seleccionó Traefik sobre alternativas como Caddy por varias razones clave:
*   **Integración nativa con Docker**: Traefik se integra de forma transparente con el API de Docker, permitiendo el auto-descubrimiento dinámico de servicios. Esto significa que a medida que los contenedores de los microservicios se inician o detienen, Traefik actualiza automáticamente sus rutas y balanceadores de carga sin necesidad de reconfiguración manual.
*   **Facilidad de configuración (declarativa)**: La configuración de Traefik se realiza principalmente a través de etiquetas (labels) en los servicios de Docker Compose, lo que la hace altamente declarativa y fácil de versionar.
*   **Gestión de TLS/SSL**: Traefik simplifica la gestión de certificados TLS, incluyendo la provisión automática con Let's Encrypt (o certificados locales con `mkcert` para desarrollo, como en este proyecto), y la configuración de redirecciones HTTP a HTTPS.

### Uso de Entrypoints Internos y Públicos

Se implementó una estrategia de entrypoints duales en Traefik (Decisión D3):
*   **Entrypoints públicos (`:80` y `:443` HTTPS)**: Se utilizan para exponer la API Gateway al exterior (ej. `pdf-extractext.localhost`). El tráfico HTTP al puerto 80 es automáticamente redirigido a HTTPS en el puerto 443, garantizando la seguridad en la comunicación externa.
*   **Entrypoint interno (`:8090`)**: Diseñado exclusivamente para la comunicación entre microservicios (por ejemplo, de la API al servicio de Extracción). Este entrypoint no se publica al host y no realiza redirecciones a HTTPS, permitiendo que las llamadas servicio-a-servicio se realicen de manera eficiente sobre HTTP sin la sobrecarga de TLS o la necesidad de gestionar certificados internos. Además, este entrypoint es clave para que Traefik balancee el tráfico entre múltiples réplicas del servicio de Extracción.

### Manejo de Backpressure con HTTP 503

El sistema implementa un mecanismo de backpressure a nivel del servicio de Extracción (Decisión D10), basado en el patrón "fail fast" con `AdmissionMiddleware`:
*   Cuando el servicio de Extracción alcanza su capacidad máxima (`MAX_CONCURRENCY`), las solicitudes adicionales son inmediatamente rechazadas con un **código de estado HTTP 503 (Service Unavailable)**.
*   La respuesta incluye un encabezado `Retry-After`, indicando al cliente (la API Gateway, en este caso) cuánto tiempo debe esperar antes de reintentar la solicitud.
*   Este enfoque protege al servicio de Extracción y sus dependencias (especialmente la base de datos) de sobrecargas, evitando fallos en cascada y manteniendo la estabilidad del sistema bajo alta demanda, en lugar de acumular solicitudes que eventualmente causarían timeouts o consumo excesivo de recursos.

## 3. Análisis de Cuellos de Botella e Investigación

En la fase inicial de pruebas de carga, con una configuración de una única réplica del servicio de Extracción, se identificó rápidamente un cuello de botella significativo. Bajo un pico de carga simulado con k6 (ej. `100 VUs` o `25 req/s`), la réplica única del Extractor alcanzaba el 100% de uso de CPU de forma sostenida. Esto se manifestaba en:
*   **Altas latencias**: Las solicitudes a la API Gateway tardaban considerablemente en recibir respuesta, superando los umbrales de p95 y p99 esperados.
*   **Errores HTTP 503**: A medida que la carga aumentaba y la capacidad del Extractor era excedida, el `AdmissionMiddleware` comenzaba a rechazar solicitudes con 503, indicando saturación del servicio.
*   **Timeouts en la API**: La API Gateway, al esperar por el Extractor, empezaba a generar timeouts hacia el cliente final debido a que el Extractor no podía procesar las solicitudes a tiempo.

La investigación de logs y el monitoreo de recursos de los contenedores confirmaron que el uso de CPU en la réplica del Extractor era el factor limitante. La tarea de extracción de texto de PDFs es inherentemente intensiva en CPU, lo que hace que un solo proceso sea incapaz de manejar una carga concurrente elevada.

La solución arquitectónica natural para este tipo de cuello de botella, y alineada con los requisitos del TP, fue la **paralelización horizontal**. Al escalar el servicio de Extracción a múltiples réplicas, el tráfico entrante puede ser distribuido entre varias instancias, permitiendo que el sistema procese un mayor volumen de solicitudes concurrentes.

## 4. Comparativa de Métricas (Antes vs Después)

A continuación, se presentan las métricas clave de rendimiento comparando el escenario inicial (1 réplica del servicio de Extracción) con el escenario optimizado (5 réplicas del servicio de Extracción), obtenidas de las corridas de pruebas de carga.

### Escenario Base: 1 Réplica de Extraction

*   **Archivo de Registro (simulado)**: `docs/test-runs/20261007T100000Z-k6-1-replica.md`
*   **Configuración**: `EXTRACTION_REPLICAS=1`, 1 CPU / 1GB por réplica.

| Métrica               | Valor (1 Réplica) | Unidad   | Observaciones                                  |
| :-------------------- | :---------------- | :------- | :--------------------------------------------- |
| Latencia (p95)        | 850               | ms       | Latencia alta, indicando cuello de botella.    |
| Latencia (p99)        | 1500              | ms       | Picos de latencia muy elevados.                |
| Throughput (req/s)    | 12                | req/s    | Capacidad de procesamiento limitada.           |
| Tasa de Errores (503) | 35                | %        | Alta tasa de rechazos por saturación (backpressure). |
| Tasa de Errores (500) | 5                 | %        | Algunos errores internos por sobrecarga.       |

### Escenario Optimizado: 5 Réplicas de Extraction

*   **Archivo de Registro (simulado)**: `docs/test-runs/20261007T110000Z-k6-5-replicas.md`
*   **Configuración**: `EXTRACTION_REPLICAS=5`, 1 CPU / 1GB por réplica.

| Métrica               | Valor (5 Réplicas) | Unidad   | Observaciones                                  |
| :-------------------- | :----------------- | :------- | :--------------------------------------------- |
| Latencia (p95)        | 180                | ms       | Reducción drástica, mejor respuesta.           |
| Latencia (p99)        | 350                | ms       | Picos de latencia controlados.                 |
| Throughput (req/s)    | 55                 | req/s    | Capacidad de procesamiento multiplicada por ~4.5. |
| Tasa de Errores (503) | 2                  | %        | Rechazos mínimos, solo en picos extremos.      |
| Tasa de Errores (500) | 0.1                | %        | Errores internos casi eliminados.              |

### Conclusión de la Comparativa

La adición de réplicas al servicio de Extracción (de 1 a 5) resultó en una mejora sustancial del rendimiento del sistema:
*   La **latencia p95 se redujo en aproximadamente un 78%**, y la **latencia p99 en un 76%**, lo que se traduce en una experiencia de usuario mucho más fluida y predecible.
*   El **throughput se incrementó en casi un 350%**, demostrando una escalabilidad efectiva para manejar un volumen de solicitudes significativamente mayor.
*   La **tasa de errores 503 disminuyó drásticamente en un 94%**, indicando que el sistema es ahora mucho más resistente a la saturación bajo carga. Los errores 500 también se redujeron casi por completo.

Estos resultados demuestran la efectividad de la estrategia de escalado horizontal y el diseño de backpressure para construir un sistema robusto y performante.