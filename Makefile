COMPOSE := docker compose

.PHONY: check up down build logs ps smoke

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
