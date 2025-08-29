# Database Password Output
output "db_password" {
  description = "The generated database password"
  value       = local.db_password
  sensitive   = true
}

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = module.vpc.public_security_group_id
}

output "private_security_group_id" {
  description = "The ID of the private security group"
  value       = module.vpc.private_security_group_id
}

output "vpc_endpoints_security_group_id" {
  description = "The ID of the VPC endpoints security group"
  value       = module.vpc.vpc_endpoints_security_group_id
}

# output "s3_vpc_endpoint_id" {
#   description = "The ID of the S3 VPC endpoint"
#   value       = module.vpc.s3_vpc_endpoint_id
# }

# output "secretsmanager_vpc_endpoint_id" {
#   description = "The ID of the Secrets Manager VPC endpoint"
#   value       = module.vpc.secretsmanager_vpc_endpoint_id
# }

# output "ecs_vpc_endpoint_id" {
#   description = "The ID of the ECS VPC endpoint"
#   value       = module.vpc.ecs_vpc_endpoint_id
# }

# S3 Outputs
output "app_data_bucket_name" {
  description = "The name of the application data bucket"
  value       = module.s3.app_data_bucket_name
}

output "app_data_bucket_arn" {
  description = "The ARN of the application data bucket"
  value       = module.s3.app_data_bucket_arn
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

# output "ecs_service_name" {
#   description = "The name of the ECS service"
#   value       = module.ecs.service_name
# }

output "ecs_load_balancer_dns_name" {
  description = "The DNS name of the ECS load balancer"
  value       = module.ecs.load_balancer_dns_name
}

output "ecs_task_role_arn" {
  description = "The ARN of the ECS task role"
  value       = module.ecs.task_role_arn
}

# Summary Outputs
output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    vpc = {
      id           = module.vpc.vpc_id
      cidr_block   = module.vpc.vpc_cidr_block
      public_subnets  = length(module.vpc.public_subnet_ids)
      private_subnets = length(module.vpc.private_subnet_ids)
    }
    storage = {
      data_bucket = module.s3.app_data_bucket_name
      # ecr_repository = aws_ecr_repository.app.name
    }
    # database = {
    #   cluster_endpoint = module.rds.cluster_endpoint
    #   database_name    = module.rds.database_name
    #   cluster_resource_id = module.rds.cluster_resource_id
    # }
    compute = {
      ecs_cluster = module.ecs.cluster_name
    }
    endpoints = {
      ecs_lb = module.ecs.load_balancer_dns_name
    }
    # vpc_endpoints = {
    #   s3 = module.vpc.s3_vpc_endpoint_id
    #   secretsmanager = module.vpc.secretsmanager_vpc_endpoint_id
    #   ecs = module.vpc.ecs_vpc_endpoint_id
    # }
  }
}
