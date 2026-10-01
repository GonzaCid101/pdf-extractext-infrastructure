# pdf-extractext-infrastructure

Bootstrap de infraestructura de **PDF Extractext** (migración de monolito a
microservicios).

## Qué demuestra

```
Traefik (provisional, entrada única)
        ▼  red `services`
   Extraction (:8001, /health)

MongoDB  ◀─ solo red `data`; 27017 no publicado; volumen nombrado
```

Levanta **Traefik + Extraction + MongoDB** sobre la arquitectura final
acordada: `Traefik → API → {Extraction, Persistence} → MongoDB`.

API y Persistence aún no existen como repos; este repo no crea placeholders.
Cuando existan, se agregan al compose en la red correspondiente (`services`
para API; `data` además para Persistence) con sus rutas de Traefik.

## Requisitos

- Docker + Docker Compose v2, Make, Bash, curl
- Repo de Extraction clonado como hermano (**PROVISIONAL**, ver
  `docs/pending-decisions.md`): `../pdf-extractext-extractor`

## Quickstart

```bash
cp .env.example .env   # ajustá EXTRACTION_CONTEXT si tu ruta difiere
make up                # valida el contexto de Extraction y levanta todo
make smoke             # verifica los 9 checks
make down
make logs / make ps    # utilidades
```

Si falta `.env` o el contexto de Extraction no existe, `make up` falla con un
mensaje que explica cómo resolverlo.

## Comprobaciones de `make smoke`

1. Los 3 servicios quedan running tras `compose up --build`.
2. Traefik responde (dashboard local, **PROVISIONAL**).
3. MongoDB pasa su healthcheck técnico de contenedor.
4. Extraction está running.
5. Extraction responde `GET /health` desde la red interna (contenedor efímero).
6. Extraction **no** es alcanzable desde el host ni vía Traefik (:80).
7. MongoDB **no** es alcanzable desde el host ni desde la red de servicios.
8. `down && up` conserva los datos de Mongo. La prueba inserta y limpia un
   documento temporal directo en Mongo (Persistence no existe aún): es solo
   una prueba de infraestructura.
9. No hay `.env` ni datos runtime versionados.

## Reglas del bootstrap

- Solo Persistence accederá a MongoDB (aislamiento por redes).
- Datos de Mongo en volumen nombrado; jamás bind-mount versionado.
- `.env` nunca versionado.
- Stack: Docker Compose v2, Traefik v3, Mongo oficial, Make, Bash, curl.
  Sin observabilidad extra, CI, k6/Vegeta ni límites de recursos.
- Lo marcado **PROVISIONAL** (Traefik, dashboard inseguro, repo hermano, tag
  de Mongo) es pendiente de equipo: [`docs/pending-decisions.md`](docs/pending-decisions.md).

## Healthchecks

El healthcheck de Mongo es **técnico** (el proceso responde a ping). La
semántica health/readiness de los microservicios es una decisión pendiente.
