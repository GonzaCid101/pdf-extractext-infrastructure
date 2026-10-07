COMPOSE := docker compose
DOMAIN  := pdf-extractext.localhost
# Propaga EXTRACTION_REPLICAS (env o `make up EXTRACTION_REPLICAS=N`) al stack.
export EXTRACTION_REPLICAS

.PHONY: check certs up down build logs ps smoke record-run load-k6 load-vegeta

# certs genera el certificado TLS local con mkcert (nunca versionar).
certs:
	@command -v mkcert >/dev/null || { echo "ERROR: falta mkcert — https://github.com/FiloSottile/mkcert#installation"; \
		echo "       Si descargás el binario suelto, ubicarlo en el PATH, p. ej.:"; \
		echo "       install mkcert ~/.local/bin/   (o /usr/local/bin/ con sudo)"; exit 1; }
	mkcert -install
	@mkdir -p traefik/certs
	mkcert -cert-file traefik/certs/cert.pem -key-file traefik/certs/key.pem \
		$(DOMAIN) "*.$(DOMAIN)"
	@echo "Certs generados en traefik/certs/ para $(DOMAIN)"

# check falla con mensaje claro si falta .env o algún contexto de build.
check:
	@test -f .env || { echo "ERROR: falta .env — ejecutá: cp .env.example .env"; exit 1; }
	@r=$${EXTRACTION_REPLICAS:-$$(grep -E '^EXTRACTION_REPLICAS=' .env | cut -d= -f2-)}; \
		r=$${r:-1}; \
		{ [ "$$r" -ge 1 ] 2>/dev/null && [ "$$r" -le 5 ] 2>/dev/null; } || { \
			echo "ERROR: EXTRACTION_REPLICAS=$$r fuera de rango (1-5, exigencia del TP)"; exit 1; }
	@$(foreach var,API_CONTEXT EXTRACTION_CONTEXT PERSISTENCE_CONTEXT, \
		ctx=$$(grep -E '^$(var)=' .env | cut -d= -f2-) ; \
		test -n "$$ctx" || { echo "ERROR: $(var) no definido en .env"; exit 1; } ; \
		test -d "$$ctx" || { echo "ERROR: no existe el contexto de build: $$ctx"; \
			echo "       Cloná el repo correspondiente como hermano de este, o ajustá"; \
			echo "       $(var) en .env a la ruta correcta."; exit 1; } ; \
		test -f "$$ctx/Dockerfile" || { echo "ERROR: $$ctx no tiene Dockerfile"; exit 1; } ; \
	)

up: check
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

build: check
	$(COMPOSE) build

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

smoke: check
	bash scripts/smoke.sh

# Pruebas de carga (Issue #4 / ADR D11): k6 spike y Vegeta 50 req/s × 30s.
# Ambas corren contra https://pdf-extractext.localhost/extract y registran
# la corrida en docs/test-runs/ con la config real del stack (record-run.sh).
# RECORD=0 corre el ataque como ensayo sin registrar (p. ej. contra un mock).
load-k6: check
	bash tests/load/run_k6.sh

load-vegeta: check
	bash tests/load/vegeta/run_vegeta.sh

# record-run genera docs/test-runs/<fechaUTC>-<tool>.md con la config real del
# stack activo. Parámetros y resultados se pasan como flags via ARGS, ej.:
#   make record-run ARGS="--tool k6 --target http://traefik:8090 --load 'abierto 25 req/s' --throughput 98.2 --success 99.7 --p50 42 --p90 120 --p95 210"
record-run:
	./scripts/record-run.sh $(ARGS)
