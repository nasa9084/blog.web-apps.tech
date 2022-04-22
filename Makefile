DOMAIN = blog.web-apps.tech
THIS_YEAR ?= $(shell date +%Y)

.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Install tools required for local development.
	@brew install hugo
	@hugo version

module-check: ## Check if all of the required submodules are correctly initialized.
	@git submodule status --recursive | awk '/^[+-]/ {err = 1; printf "\033[31mWARNING\033[0m Submodule not initialized: \033[34m%s\033[0m\n",$$2} END { if (err != 0) print "You need to run \033[32mmake module-init\033[0m to initialize missing modules first"; exit err }' 1>&2

module-init: ## Initialize required submodules.
	@echo "Initializing submodules..." 1>&2
	@git submodule update --init --recursive --depth 1

update-theme: ## Update PaperMod theme
	@git submodule update --remote --merge


.PHONY: serve
serve: ## serve locally for development.
	@cd $(DOMAIN); hugo server --baseURL "http://localhost" --environment development --buildDrafts

new/%:
	@cd $(DOMAIN); hugo new --kind post --editor=emacs post/$(THIS_YEAR)/$(notdir $@)
