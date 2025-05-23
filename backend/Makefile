include .envrc

DB_USER ?= mgv_user
DB_NAME ?= mgv_hub_db

MIGRATIONS_PATH := ./cmd/migrate/migrations
SCHEMA_SQL_PATH := ./scripts/schema.sql
DB_SERVICE_NAME := db

.PHONY: server
dev:
	@go run ./cmd/api


.PHONY: setup-db
setup-db:
	@echo "Ensuring Postgresql container is running..."
	docker-compose up -d $(DB_SERVICE_NAME)
	@echo "Waiting a few seconds for the database to be ready..."
	sleep 5
	@echo "Applying database schema from $(SCHEMA_SQL_PATH)..."
	cat $(SCHEMA_SQL_PATH) | docker-compose exec -T $(DB_SERVICE_NAME) psql -U $(DB_USER) -d $(DB_NAME)
	@echo "Database schema setup complete."

.PHONY: reset-db
reset-db:
	@echo "Ensuring Postgresql container is running..."
	docker-compose up -d $(DB_SERVICE_NAME)
	@echo "Waiting a few seconds for the database to be ready..."
	sleep 5
	@echo "Resetting database schema (dropping and recreating tables) from $(SCHEMA_SQL_PATH)..."
	cat $(SCHEMA_SQL_PATH) | docker-compose exec -T $(DB_SERVICE_NAME) psql -U $(DB_USER) -d $(DB_NAME)
	@echo "Database schema reset complete."

