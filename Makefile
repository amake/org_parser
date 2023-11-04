SHELL := /usr/bin/env bash

.PHONY: test
test: ## Run all tests
test: test-unit test-example test-roundtrip

.PHONY: test-unit
test-unit:
	dart test --chain-stack-traces

.PHONY: test-example
test-example:
	diff <(dart example/example.dart) test/example-gold.txt

roundtrip = diff <(dart test/bin/roundtrip.dart $(1)) $(1)

.PHONY: test-roundtrip
test-roundtrip:
	$(call roundtrip,test/org-manual.org)
	$(call roundtrip,test/org-syntax.org)

.PHONY: help
help: ## Show this help text
	$(info usage: make [target])
	$(info )
	$(info Available targets:)
	@awk -F ':.*?## *' '/^[^\t].+?:.*?##/ \
         {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
