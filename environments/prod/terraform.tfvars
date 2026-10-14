# Production : haute disponibilité, protection contre la suppression, HTTPS uniquement.
environment = "prod"
owner       = "platform-team"

# Réseau
vpc_cidr           = "10.20.0.0/16"
az_count           = 3
single_nat_gateway = false # une NAT Gateway par AZ
alb_ingress_cidrs  = ["0.0.0.0/0"]
# Certificat ACM (même région) de votre domaine - OBLIGATOIRE
certificate_arn = "arn:aws:acm:eu-west-3:<ACCOUNT_ID>:certificate/<CERTIFICATE_ID>"

# Application - tag immuable poussé dans le dépôt ECR de cet environnement
container_image        = "<ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/iac-portfolio-prod:1.0.0"
container_port         = 8080
health_check_path      = "/"
app_cpu                = 512
app_memory             = 1024
app_desired_count      = 3
app_min_capacity       = 3
app_max_capacity       = 12
use_fargate_spot       = false
enable_execute_command = false

# Base de données
db_instance_class              = "db.t4g.medium"
db_allocated_storage           = 50
db_max_allocated_storage       = 500
db_multi_az                    = true
db_backup_retention_days       = 30
db_performance_insights        = true
db_connections_alarm_threshold = 300

# Exploitation
deletion_protection = true
log_retention_days  = 365
alarm_emails        = ["astreinte@example.com"]
