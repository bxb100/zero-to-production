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

config_file := .prod.env
export DATABASE_URL=$(shell cat $(config_file) | grep "DATABASE_URL" | awk -F '=' '{print $$NF}')

.PHONY: infra-plan infra infra-down fly-prep fly-deploy fly-run
infra-plan: ## terraform init and plan
ifeq ($(strip $(FLY_API_TOKEN)),)
	@echo "FLY_API_TOKEN is empty, make sure the environment exist this variable"
	@false
endif
ifeq ($(strip $(NEON_TOKEN)),)
	@echo "NEON_TOKEN is empty, make sure the environment exist this variable"
	@false
endif
	@terraform init
	@terraform plan

infra: infra-plan ## terraform apply
	@terraform apply --auto-approve
	@echo "RUN direnv allow to effect the chanages"

infra-down: ## terraform destroy
	@terraform destroy --auto-approve

fly-prep: ## prepare postgres database for fly
ifeq ($(strip $(DATABASE_URL)),)
	@echo "'$(config_file)' is exist and contains DATABASE_URL or not"
	@false
endif
	@echo DATABASE_URL is $(DATABASE_URL)
	@# notice we need to export the DATABASE_URL variable for sqlx to run
	@sqlx migrate info && sqlx migrate run

fly-deploy: fly-prep ## deploy to fly
	@#fly secrets import < .secrets.env
	@fly deploy

fly-run: ## build infra and deploy fly
	@$(MAKE) infra
	@$(MAKE) fly-deploy
