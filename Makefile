# Usage : make <cible> ENV=dev|prod
ENV ?= dev
ENV_DIR := environments/$(ENV)
TF := terraform

.DEFAULT_GOAL := help
.PHONY: help bootstrap init plan apply destroy output fmt validate test lint security check clean

help: ## Afficher les cibles disponibles
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Créer le backend distant du state (S3 + DynamoDB + KMS)
	cd bootstrap && $(TF) init && $(TF) apply
	cd bootstrap && $(TF) output -raw backend_config

init: ## terraform init avec le backend distant de ENV
	cd $(ENV_DIR) && $(TF) init -backend-config=backend.hcl

plan: init ## Planifier ENV dans le fichier tfplan
	cd $(ENV_DIR) && $(TF) plan -out=tfplan

apply: ## Appliquer le plan enregistré de ENV
	cd $(ENV_DIR) && $(TF) apply tfplan

destroy: init ## Détruire ENV
	cd $(ENV_DIR) && $(TF) destroy

output: ## Afficher les outputs de ENV
	cd $(ENV_DIR) && $(TF) output

fmt: ## Formater tous les fichiers
	$(TF) fmt -recursive

validate: ## Valider chaque module racine (sans backend)
	@for d in bootstrap environments/dev environments/prod; do \
		echo "==> $$d"; \
		(cd $$d && $(TF) init -backend=false -input=false >/dev/null && $(TF) validate) || exit 1; \
	done

test: ## Lancer les suites terraform test (provider AWS simulé)
	@for d in modules/vpc modules/security-groups environments/dev environments/prod; do \
		echo "==> $$d"; \
		(cd $$d && $(TF) init -backend=false -input=false >/dev/null && $(TF) test) || exit 1; \
	done

lint: ## Lancer TFLint sur tous les répertoires
	tflint --init --config "$(CURDIR)/.tflint.hcl"
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

security: ## Lancer Checkov
	checkov -d . --config-file .checkov.yaml

check: ## fmt (vérification) + validate + test + lint + security
	$(TF) fmt -recursive -check
	$(MAKE) validate test lint security

clean: ## Supprimer les répertoires de travail Terraform et les plans locaux
	find . -type d -name .terraform -prune -exec rm -rf {} +
	find . -name tfplan -delete
