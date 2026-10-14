# Développement : coûts optimisés, facile à détruire.
environment = "dev"
owner       = "platform-team"

# Réseau
vpc_cidr           = "10.10.0.0/16"
az_count           = 2
single_nat_gateway = true # environ 33 USD/mois économisés par NAT Gateway évitée
alb_ingress_cidrs  = ["0.0.0.0/0"]
certificate_arn    = null # HTTP uniquement en dev ; renseigner l'ARN d'un certificat ACM pour activer le HTTPS

# Application - remplacer par "<ecr_repository_url>:<tag>" une fois votre image poussée
container_image        = "nginxinc/nginx-unprivileged:stable-alpine"
container_port         = 8080
health_check_path      = "/"
app_cpu                = 256
app_memory             = 512
app_desired_count      = 1
app_min_capacity       = 1
app_max_capacity       = 3
use_fargate_spot       = true
enable_execute_command = true

# Base de données
db_instance_class        = "db.t4g.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 50
db_multi_az              = false
db_backup_retention_days = 1
db_performance_insights  = false

# Exploitation
deletion_protection = false
log_retention_days  = 14
alarm_emails        = [] # ex. ["vous@example.com"]
