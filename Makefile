COMPOSE := docker compose

.PHONY: check up down build logs ps smoke

# check falla con mensaje claro si falta .env o el contexto de Extraction.
check:
	@test -f .env || { echo "ERROR: falta .env — ejecutá: cp .env.example .env"; exit 1; }
	@ctx=$$(grep -E '^EXTRACTION_CONTEXT=' .env | cut -d= -f2-) ; \
	test -n "$$ctx" || { echo "ERROR: EXTRACTION_CONTEXT no definido en .env"; exit 1; } ; \
	test -d "$$ctx" || { echo "ERROR: no existe el contexto de Extraction: $$ctx"; \
		echo "       Cloná el repo de Extraction como hermano de este, o ajustá"; \
		echo "       EXTRACTION_CONTEXT en .env a la ruta correcta."; exit 1; } ; \
	test -f "$$ctx/Dockerfile" || { echo "ERROR: $$ctx no tiene Dockerfile"; exit 1; }

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
