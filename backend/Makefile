include .envrc
MIGRATIONS_PATH=./cmd/migrate/migrations

.PHONY: server
dev:
	@go run ./cmd/api

.PHONY: migrate-reset
migrate-reset:
	@echo "Resetting database..."
	# Drop all tables (postgres version)
	@psql $(DSN) -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" || true

