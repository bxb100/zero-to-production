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

config_file := .secrets.env
export DATABASE_URL=$(shell cat $(config_file) | grep "DATABASE_URL" | awk -F '=' '{print $$NF}')
export FLY_API_TOKEN=$(shell cat $(config_file) | grep "FLY_API_TOKEN" | awk -F '=' '{print $$NF}')
export NEON_TOKEN=$(shell cat $(config_file) | grep "NEON_TOKEN" | awk -F '=' '{print $$NF}')

.PHONY: infra-plan infra infra-destroy infra-util fly-prep fly-deploy fly-run
infra-plan: ## terraform init and plan
ifeq ($(strip $(FLY_API_TOKEN)),)
	@echo "FLY_API_TOKEN is empty, please check .secrets.env"
	@false
endif
ifeq ($(strip $(NEON_TOKEN)),)
	@echo "NEON_TOKEN is empty, please check .secrets.env"
	@false
endif
	@terraform init
	@terraform plan

infra: infra-plan ## terraform apply
	@terraform apply --auto-approve
	@$(MAKE) infra-util

infra-destroy: ## terraform destroy
	@terraform destroy --auto-approve
	@sed -i '.bak' '/^DATABASE_URL/d' $(config_file)

infra-util: ## run this when infra is build done
	@if ! grep -q "DATABASE_URL" $(config_file); then \
      echo 'change the database url'; \
      echo "DATABASE_URL=$$(terraform output postgres_uri | sed -E 's/\"//g')" >> $(config_file); \
    fi

fly-prep: infra-util ## prepare postgres database for fly
ifeq ($(strip $(DATABASE_URL)),)
	@echo "DATABASE_URL is empty, please check .secrets.env"
	@false
endif
	@echo DATABASE_URL is $(DATABASE_URL)
	@# notice we need to export the DATABASE_URL variable for sqlx to run
	@sqlx migrate info && sqlx migrate run

fly-deploy: fly-prep ## deploy to fly
	@#fly secrets import < .secrets.env
	@fly deploy

fly-run: ## prepare infrastructure, database schema, and deploy to fly
	@$(MAKE) infra
	@$(MAKE) fly-deploy