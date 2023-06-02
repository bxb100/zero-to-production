#com.jetbrains.cidr.cpp.makefile
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
# https://www.gnu.org/software/make/manual/html_node/Special-Variables.html
.DEFAULT_GOAL := help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

LOG = RUST_LOG=$(level)
ifeq ($(level),)
level := info
endif

.PHONY: clean check test run docker docker-run prepare
clean: ## cargo clean
	@cargo clean

check: ## cargo check
	@cargo check

test: ## cargo test
	@cargo test

run: check ## cargo check and run, default log level is INFO
	$(LOG) cargo run

docker: ## build a Docker image
	@docker build --tag zero2prod --file Dockerfile .

docker-run: ## run the Docker image
	@docker run --network=host --rm zero2prod

prepare: ## prepare sqlx offline metadata
	# It must be invoked as a cargo subcommand
    # All options after `--` are passed to cargo itself
    # We need to point it at our library since it contains
    # all our SQL queries.
	cargo sqlx prepare -- --lib

export DATABASE_URL=$(shell cat .secrets.env | grep "DATABASE_URL" | awk -F '=' '{print $$NF}')
export FLY_API_TOKEN=$(shell cat .secrets.env | grep "FLY_API_TOKEN" | awk -F '=' '{print $$NF}')
export NEON_TOKEN=$(shell cat .secrets.env | grep "NEON_TOKEN" | awk -F '=' '{print $$NF}')

.PHONY: fly-infra fly-prep fly-run
fly-infra: ## terraform apply
ifeq ($(strip $(FLY_API_TOKEN)),)
	@echo "FLY_API_TOKEN is empty, please check .secrets.env"
	@false
endif
ifeq ($(strip $(NEON_TOKEN)),)
	@echo "NEON_TOKEN is empty, please check .secrets.env"
	@false
endif
	# should only run once
	@terraform apply --auto-approve

fly-prep: ## prepare postgres database for fly
ifeq ($(strip $(DATABASE_URL)),)
	@echo "DATABASE_URL is empty, please check .secrets.env"
	@false
endif
	@echo DATABASE_URL is $(DATABASE_URL)
	@# notice we need to export the DATABASE_URL variable for sqlx to run
	@sqlx migrate info && sqlx migrate run

fly-run: fly-prep ## deploy to fly
	@#fly secrets import < .secrets.env
	@fly deploy
