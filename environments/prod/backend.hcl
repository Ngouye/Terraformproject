# Valeurs affichées par `terraform output backend_config` dans bootstrap/.
bucket         = "iac-portfolio-tfstate-<ACCOUNT_ID>-eu-west-3"
region         = "eu-west-3"
dynamodb_table = "iac-portfolio-tf-locks"
kms_key_id     = "arn:aws:kms:eu-west-3:<ACCOUNT_ID>:key/<KEY_ID>"
encrypt        = true
