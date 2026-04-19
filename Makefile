# Convenience targets for common tasks.
# Run `make help` to list them.

.DEFAULT_GOAL := help

.PHONY: help up down restart logs ps build migrate migration shell-backend shell-db clean nuke

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

up: ## Start all services (detached)
	docker-compose up -d --build
	@echo ""
	@echo "Services starting. Give it ~30s on first run."
	@echo "  Frontend:  http://localhost:5173"
	@echo "  Backend:   http://localhost:8000"
	@echo "  API docs:  http://localhost:8000/docs"
	@echo ""
	@echo "Run 'make migrate' once DB is healthy to create tables."

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

logs: ## Tail logs from all services
	docker-compose logs -f

ps: ## Show running containers
	docker-compose ps

build: ## Rebuild images
	docker-compose build

migrate: ## Apply DB migrations
	docker-compose exec backend alembic upgrade head

migration: ## Create a new migration (usage: make migration name="add users table")
	docker-compose exec backend alembic revision --autogenerate -m "$(name)"

shell-backend: ## Open a shell in the backend container
	docker-compose exec backend bash

shell-db: ## Open psql against the db
	docker-compose exec db psql -U app -d app

clean: ## Stop services and remove volumes (DESTROYS DB DATA)
	docker-compose down -v

nuke: ## clean + remove built images
	docker-compose down -v --rmi local
