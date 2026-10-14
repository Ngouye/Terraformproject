# Configuration TFLint - bonnes pratiques Terraform et règles spécifiques AWS
# (types d'instance invalides, arguments obsolètes...).
# Usage : tflint --init && tflint --recursive --config "$(pwd)/.tflint.hcl"
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.49.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Conventions de nommage snake_case.
rule "terraform_naming_convention" {
  enabled = true
}

# Chaque variable et chaque output doit être documenté.
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

# Chaque variable doit être typée.
rule "terraform_typed_variables" {
  enabled = true
}

# Aucune variable, local ou data source inutilisé.
rule "terraform_unused_declarations" {
  enabled = true
}
