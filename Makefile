SHELL := /usr/bin/env bash

.PHONY: test
test: # Run all tests
test: test-unit test-example

.PHONY: test-unit
test-unit:
	dart test

.PHONY: test-example
test-example:
	diff <(dart example/example.dart) test/example-gold.txt

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
