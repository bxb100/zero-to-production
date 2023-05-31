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

.PHONY: fly-prep fly-run
fly-prep: ## prepare postgres database for fly

	@export $$(cat .secrets.env | sed -n '1p') && sqlx migrate info && sqlx migrate run

fly-run: fly-prep ## deploy to fly
	@fly deploy
	@fly secrets import < .secrets.env
