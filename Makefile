COMPOSE := docker compose
DOMAIN  := pdf-extractext.localhost

.PHONY: check certs up down build logs ps smoke

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
	@$(foreach var,EXTRACTION_CONTEXT PERSISTENCE_CONTEXT, \
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
