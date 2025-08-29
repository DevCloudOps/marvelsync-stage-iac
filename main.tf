# Random Password for Database
resource "random_password" "db_password" {
  count   = var.db_password == null ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  db_password = var.db_password != null ? var.db_password : random_password.db_password[0].result
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  key_name            = var.key_name
  tags                = var.tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# ECR Repository
# resource "aws_ecr_repository" "app" {
#   name                 = "${var.project_name}-acr"
#   image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }

#   encryption_configuration {
#     encryption_type = "AES256"
#   }

#   tags = merge(var.tags, {
#     Name = "${var.project_name}-acr"
#   })
# }

# ECR Lifecycle Policy
# resource "aws_ecr_lifecycle_policy" "app" {
#   repository = aws_ecr_repository.app.name

#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Keep last 30 images"
#         selection = {
#           tagStatus     = "any"
#           countType     = "imageCountMoreThan"
#           countNumber   = 30
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }

# # ECR Repository Policy
# resource "aws_ecr_repository_policy" "app" {
#   repository = aws_ecr_repository.app.name

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowPullFromECSTasks"
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "ecr:BatchCheckLayerAvailability"
#         ]
#       }
#     ]
#   })
# }

# RDS Aurora Module
module "rds" {
  source = "./modules/rds"
  project_name              = var.project_name
  environment               = var.environment
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  private_security_group_id = module.vpc.private_security_group_id
  ecs_security_group_id    = module.ecs.ecs_security_group_id
  db_instance_class        = var.db_instance_class
  db_username              = var.db_username
  db_password              = local.db_password
  db_name                  = var.db_name
  create_replica           = false
  tags                     = var.tags
  snapshot_identifier      = "arn:aws:rds:ap-south-1:959959864795:snapshot:jarwiz-stage-iac-setup"
  skip_final_snapshot      = true

  depends_on = [module.vpc]
}

# ECS Module - Updated for EC2-backed ECS with t3a.medium
module "ecs" {
  source = "./modules/ecs"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                   = module.vpc.vpc_id
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_subnet_ids       = module.vpc.private_subnet_ids
  public_security_group_id = module.vpc.public_security_group_id
  private_security_group_id = module.vpc.private_security_group_id
  s3_data_bucket_arn       = module.s3.app_data_bucket_arn
  backend_image            = "959959864795.dkr.ecr.ap-south-1.amazonaws.com/jarwiz-acr:stage-backend-latest"
  key_name                 = var.key_name
  # Task definitions resources - these should fit within a t3a.medium instance
  backend_task_cpu         = 1024  # 1 vCPU
  backend_task_memory      = 2048  # 2 GB
  # Fixed counts for staging environment
  backend_service_desired_count = 1
  service_min_count        = 1
  service_max_count        = 1  # Set max count equal to min for fixed-size environment
  backend_environment      = [
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = "docker"
    },
    {
      name  = "JAVA_OPTS"
      value = "-Xms512m -Xmx768m -XX:+UseG1GC -XX:+UseContainerSupport"
    },
    {
      name  = "SPRING_JPA_HIBERNATE_DDL_AUTO"
      value = "update"
    },
    {
      name  = "SPRING_JPA_SHOW_SQL"
      value = "false"
    }
  ]
  backend_secrets          = [
    # All environment variables from the single secret
    # {
    #   name      = "DB_PASSWORD"
    #   valueFrom = "arn:aws:secretsmanager:ap-south-1:959959864795:secret:stage/jarwiz/qms/env-iDOjMq:DB_PASSWORD::"
    # },
    # {
    #   name      = "AWS_ACCESS_KEY_ID"
    #   valueFrom = "arn:aws:secretsmanager:ap-south-1:959959864795:secret:stage/jarwiz/qms/env-iDOjMq:AWS_ACCESS_KEY_ID::"
    # },
    # {
    #   name      = "AWS_SECRET_ACCESS_KEY"
    #   valueFrom = "arn:aws:secretsmanager:ap-south-1:959959864795:secret:stage/jarwiz/qms/env-iDOjMq:AWS_SECRET_ACCESS_KEY::"
    # },
    # {
    #   name      = "FIREBASE_API_KEY"
    #   valueFrom = "arn:aws:secretsmanager:ap-south-1:959959864795:secret:stage/jarwiz/qms/env-iDOjMq:FIREBASE_API_KEY::"
    # }
  ]
  tags                     = var.tags

  depends_on = [module.vpc]
}

