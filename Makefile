#!/usr/bin/env make -f
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent

.DEFAULT_GOAL := help
help: Makefile
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'


# =============================================================================
# Common
# =============================================================================
install:
	command -v goenv > /dev/null && goenv install --skip-existing "$$(goenv local)"
	go mod download
.PHONY: install

init:  ## Initialize project repository
	pre-commit autoupdate
	pre-commit install --install-hooks --hook-type pre-commit --hook-type commit-msg
.PHONY: init


# =============================================================================
# CI
# =============================================================================
ci: lint test scan  ## Run all CI tasks
.PHONY: ci

format:  ## Run autoformatters
	terraform fmt -recursive -list=true .
.PHONY: format

lint:  ## Run all linters
	terraform fmt -recursive -list=true -check .
	for tfdir in $$(find . -type f -name '*.tf' -exec dirname {} \; | sort | uniq)
	do
		echo "Validating $${tfdir}"
		terraform -chdir="$${tfdir}" validate
	done
.PHONY: lint

test:  ## Run tests
	go test ./...
.PHONY: test

scan:  ## Run scans

.PHONY: scan


# =============================================================================
# Handy Scripts
# =============================================================================
clean:  ## Remove temporary files
	find . -type d -name '.terraform' -exec rm -rf {} \; 2>/dev/null || true
	find . -type f -name '.terraform.lock.hcl' -delete
	find . -regex '.*/terraform\.\(tfstate\|tfplan\|tfstate\.backup\)' -delete
.PHONY: clean
