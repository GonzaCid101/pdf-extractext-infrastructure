# Consul — registro de servicios y configuración

Consul corre como server único (`bootstrap_expect: 1`) dentro de la red
`services`. Su puerto `8500` no se publica al host: la UI y la API HTTP solo son
alcanzables desde la red interna.

## Endpoints

| Uso | Endpoint |
| --- | --- |
| Leader | `GET /v1/status/leader` |
| Catálogo | `GET /v1/catalog/services` |
| Registro | `PUT /v1/agent/service/register` |
| Baja | `PUT /v1/agent/service/deregister/<id>` |
| Health passing | `GET /v1/health/service/<servicio>?passing=true` |
| KV | `GET/PUT /v1/kv/<clave>` (`?recurse` para prefijos) |

Todas las llamadas HTTP deben enviar `X-Consul-Token: $CONSUL_HTTP_TOKEN`. El CLI
(`consul kv`, `consul members`, etc.) toma el token de `CONSUL_HTTP_TOKEN`.

## ACL

La configuración se renderiza desde `config/consul.json.tmpl` al arrancar. El
token de desarrollo vive en `.env` (`CONSUL_HTTP_TOKEN`) y nunca se versiona; el
entrypoint lo inyecta en `/tmp/consul.json` porque el bind mount de
`/consul/config` es de solo lectura.

## Web UI

Por diseño seguro y aislamiento de red, el puerto `8500` no está expuesto directamente en el host.

### Acceso local (Recomendado)
Para interactuar con la interfaz gráfica en el navegador durante desarrollo o demostraciones:

```bash
make consul-ui
```
1. Abre un túnel temporal hacia **[http://localhost:8500/ui/](http://localhost:8500/ui/)**.
2. Te muestra el `CONSUL_HTTP_TOKEN` para autenticarte (botón *Log in* arriba a la derecha).
3. Con `Ctrl+C` se cierra el túnel manteniendo la red interna aislada.

### Acceso vía red interna (Traefik)
Internamente, Traefik enruta hacia la UI de Consul en el entrypoint privado `:8090`:

```bash
docker run --rm --network pdf-extractext_services curlimages/curl:8.10.1 \
  -H 'Host: consul.pdf-extractext.localhost' http://traefik:8090/ui/
```

## KV

Las claves siguen `pdf-extractext/config/<servicio>/<CLAVE>`. Se cargan con
`scripts/consul-kv-seed.sh` (o el servicio efímero `consul-seed`) y se leen con:

```bash
docker compose exec consul consul kv get -recurse pdf-extractext/config/
```
