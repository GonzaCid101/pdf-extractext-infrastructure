# pdf-extractext-infrastructure

Bootstrap de infraestructura de **PDF Extractext** (migración de monolito a
microservicios).

## Qué demuestra

```
Traefik (provisional, entrada única)
        ▼  red `services`
   Extraction (:8001, /health)
   Persistence (:8002, /health) ─┐
                                 ▼  red `data`
MongoDB  ◀─ solo Persistence; 27017 no publicado; volumen nombrado
```

Levanta **Traefik + Extraction + Persistence + MongoDB** sobre la arquitectura
final acordada: `Traefik → API → {Extraction, Persistence} → MongoDB`.

El repo de API aún no existe; este repo no crea placeholders. Cuando exista,
se agrega al compose en la red `services` con sus rutas de Traefik.

## Requisitos

- Docker + Docker Compose v2, Make, Bash, curl
- Repos de Extraction y Persistence clonados como hermanos (ver
  `docs/pending-decisions.md`): `../pdf-extractext-extractor` y
  `../pdf-extractext-persistence`

## Quickstart

```bash
cp .env.example .env   # ajustá *_CONTEXT si tus rutas difieren
make up                # valida los contextos de build y levanta todo
make smoke             # verifica los 12 checks
make down
make logs / make ps    # utilidades
```

Si falta `.env` o algún contexto de build no existe, `make up` falla con un
mensaje que explica cómo resolverlo.

## Comprobaciones de `make smoke`

1. Los 4 servicios quedan running tras `compose up --build`.
2. Traefik responde (dashboard local, **PROVISIONAL**).
3. MongoDB pasa su healthcheck técnico de contenedor.
4. Extraction está running.
5. Extraction responde `GET /health` desde la red interna (contenedor efímero).
6. Extraction **no** es alcanzable desde el host ni vía Traefik (:80).
7. Persistence responde `GET /health` desde la red interna.
8. Persistence **no** es alcanzable desde el host ni vía Traefik (:80).
9. MongoDB **no** es alcanzable desde el host ni desde la red de servicios.
10. Persistence garantizó el índice único `checksum_1` en Mongo (ownership).
11. `down && up` conserva los datos de Mongo. La prueba inserta y limpia un
    documento temporal directo en Mongo: es solo una prueba de infraestructura.
12. No hay `.env` ni datos runtime versionados.

## Reglas del bootstrap

- Solo Persistence accederá a MongoDB (aislamiento por redes).
- Datos de Mongo en volumen nombrado; jamás bind-mount versionado.
- `.env` nunca versionado.
- Stack: Docker Compose v2, Traefik v3, Mongo oficial, Make, Bash, curl.
  Sin observabilidad extra, CI, k6/Vegeta ni límites de recursos.
- Lo marcado **PROVISIONAL** (Traefik, dashboard inseguro) es pendiente de
  equipo: [`docs/pending-decisions.md`](docs/pending-decisions.md).
- Resuelto: versión de MongoDB (`mongo:8`) y build desde repos hermanos.

## Healthchecks

El healthcheck de Mongo es **técnico** (el proceso responde a ping). La
semántica health/readiness de los microservicios es una decisión pendiente.
