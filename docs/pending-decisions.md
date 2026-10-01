# Decisiones pendientes de equipo

Este bootstrap no cierra ninguna de estas decisiones. Todo lo que las toca en
el repo está marcado **PROVISIONAL**.

1. **Host público, TLS y routing de producción de Traefik.** Config actual:
   entrypoint `web` en :80 y dashboard con `api.insecure=true`, solo para
   desarrollo. Nunca llevar `api.insecure` a producción.
2. **Health/readiness de los microservicios** (rutas, `depends_on`). El
   healthcheck de Mongo es solo verificación operativa del contenedor.
3. **Balanceo/discovery de Extraction y destino lógico API→réplicas.**
   Capacidad futura (`--scale`), no implementada. Alternativas detectadas
   (del repo de referencia de la cátedra), ambas **PENDIENTES**:
   a. **Docker DNS round-robin:** `--scale extraction=N`; API llama a un
      único nombre de servicio. Simple; Traefik queda solo en el borde;
      coherente con retries centralizados en API.
   b. **Traefik como balanceador interno:** `deploy.replicas` + labels; un
      backend por réplica (patrón `whoami`). Visible en el dashboard, pero
      mete a Traefik en el camino interno API→Extraction y sus middlewares
      de retry/circuit breaker entrarían en conflicto con los retries de API.
4. **Comportamiento 429/503 ante saturación.**
5. **Valores de CPU/memoria** (límites de recursos).
6. **Versión de MongoDB.** El tag en `MONGO_IMAGE` es provisional.
7. **Repos hermanos vs imágenes construidas/publicadas.** Hoy:
   `EXTRACTION_CONTEXT` apunta al repo hermano (solución local simple).
8. **Entorno de carga:** k6 / Vegeta / PDFs de prueba.
9. **Herramientas adicionales.** Si Bash/Make no alcanzan, se evalúa en una
   Issue antes de agregar nada.
