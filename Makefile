DOMAIN = blog.web-apps.tech
THIS_YEAR ?= $(shell date +%Y)

.PHONY: help
help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Install tools required for local development.
	@brew install hugo
	@hugo version

.PHONY: module-check
module-check: ## Check if all of the required submodules are correctly initialized.
	@git submodule status --recursive | awk '/^[+-]/ {err = 1; printf "\033[31mWARNING\033[0m Submodule not initialized: \033[34m%s\033[0m\n",$$2} END { if (err != 0) print "You need to run \033[32mmake module-init\033[0m to initialize missing modules first"; exit err }' 1>&2

.PHONY: module-init
module-init: ## Initialize required submodules.
	@echo "Initializing submodules..." 1>&2
	@git submodule update --init --recursive --depth 1

.PHONY: update-theme
update-theme: ## Update PaperMod theme
	@git submodule update --remote --merge

.ONESHELL:
.PHONY: serve
serve: ## serve locally for development.
	@cd getogp
	@docker build -t getogp .
	@docker run --name getogp -p 8080:8080 --rm -d getogp
	@echo "getOGP server is availeble at http://localhost:8080"
	@cd ../$(DOMAIN)
	@hugo server --baseURL "http://localhost" --environment development --buildDrafts
	@docker stop getogp

new/%: ## create a new article
	@cd $(DOMAIN); hugo new --kind post post/$(THIS_YEAR)/$(notdir $@) | sed -E 's/Content dir "(.+)" created/\1/' | tr -d "\n" | pbcopy; pbpaste | xargs open
