.PHONY: up migrate attach build down logs console bash rubocop test

up:
	docker compose up -d

migrate:
	docker compose run --rm web rails db:migrate

attach:
	docker compose attach web

build:
	docker compose build

down:
	docker compose down

logs:
	docker compose logs -f

console:
	docker compose run --rm web rails console

bash:
	docker compose run --rm web bash

rubocop:
	docker compose run --rm web rubocop

rubocop-fix:
	docker compose run --rm web rubocop -A

test:
	docker compose run --rm web rails test

db-create:
	docker compose run --rm web rails db:create

db-reset:
	docker compose run --rm web rails db:reset

db-seed:
	docker compose run --rm web rails db:seed

init:
	docker compose run --rm web rails app:init
