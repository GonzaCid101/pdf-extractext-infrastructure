COMPOSE := docker compose
DOMAIN  := pdf-extractext.localhost
# Propaga EXTRACTION_REPLICAS (env o `make up EXTRACTION_REPLICAS=N`) al stack.
export EXTRACTION_REPLICAS

.PHONY: check test test-infra consul-check consul-ui certs up down build logs ps smoke record-run load-k6 load-vegeta kv-seed

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

# test valida sintaxis, configuración y tests rápidos sin levantar contenedores
test:
	@echo "== test: sintaxis bash =="
	@for f in $$(find . -type f -name '*.sh' ! -path '*/\.git/*' ! -path '*/\.opencode/*'); do \
		bash -n "$$f" || exit 1; \
	done
	@echo "OK"
	@echo "== test: sintaxis python =="
	@for f in $$(find . -type f -name '*.py' ! -path '*/\.git/*' ! -path '*/\.opencode/*'); do \
		python3 -m py_compile "$$f" || exit 1; \
	done
	@echo "OK"
	@echo "== test: sintaxis js =="
	@if command -v node >/dev/null 2>&1; then \
		for f in $$(find . -type f -name '*.js' ! -path '*/\.git/*' ! -path '*/\.opencode/*'); do \
			node --check "$$f" || exit 1; \
		done; \
		echo "OK"; \
	else \
		echo "SKIP (node no disponible)"; \
	fi
	@echo "== test: docker compose config =="
	@if [ -f .env ]; then \
		$(COMPOSE) config -q || exit 1; \
	else \
		$(COMPOSE) --env-file .env.example config -q || exit 1; \
	fi
	@echo "OK"
	@echo "== test: unitarios infra =="
	@if [ -f tests/load/test_mock_api.py ]; then \
		python3 -m unittest tests.load.test_mock_api 2>&1 | tail -5 || exit 1; \
	fi
	@if [ -f tests/load/test_metrics_parse.sh ]; then \
		bash tests/load/test_metrics_parse.sh || exit 1; \
	fi
	@echo "OK"

# test-infra corre la suite de contrato de Consul/Traefik/KV sin levantar el stack.
test-infra:
	@bash scripts/tests/run.sh
	@echo "== test-infra: sintaxis bash =="
	@for f in $$(find scripts consul -type f -name '*.sh'); do bash -n "$$f" || exit 1; done
	@echo "OK"
	@echo "== test-infra: shellcheck =="
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh consul/entrypoint.sh consul/seed/seed.sh || exit 1; \
	else \
		echo "SKIP (shellcheck no disponible; se usó bash -n)"; \
	fi

# consul-check verifica leader, catálogo y claves del KV (requiere el stack arriba).
consul-check:
	bash scripts/consul-check.sh

# consul-ui abre un túnel temporal hacia la UI de Consul en http://localhost:8500/ui/ (Ctrl+C para cerrar).
consul-ui:
	@echo "Consul UI disponible en: http://localhost:8500/ui/"
	@echo "Token ACL: $$(grep -E '^CONSUL_HTTP_TOKEN=' .env 2>/dev/null | cut -d= -f2-)"
	@echo "Presioná Ctrl+C para cerrar el acceso."
	@docker run --rm -it --network pdf-extractext_services -p 8500:8500 alpine/socat TCP-LISTEN:8500,fork TCP:consul:8500

up: check
	$(COMPOSE) up -d --build --remove-orphans

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

# kv-seed carga consul/seed/keys.env sin pisar claves existentes (SEED_FORCE=true las pisa).
kv-seed:
	bash scripts/consul-kv-seed.sh

# Pruebas de carga (ADR D12): k6 spike y Vegeta 50 req/s × 30s contra
# https://pdf-extractext.localhost/extract; registran en docs/test-runs/.
# RECORD=0 corre como ensayo sin registrar (p. ej. contra un mock).
load-k6: check
	bash tests/load/run_k6.sh

load-vegeta: check
	bash tests/load/vegeta/run_vegeta.sh

# record-run genera docs/test-runs/<fechaUTC>-<tool>.md con la config real del
# stack activo. Ej.:
#   make record-run ARGS="--tool k6 --target http://traefik:8090 --load 'abierto 25 req/s' --throughput 98.2 --success 99.7 --p50 42 --p90 120 --p95 210"
record-run:
	./scripts/record-run.sh $(ARGS)
