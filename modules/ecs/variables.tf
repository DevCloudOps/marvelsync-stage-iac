variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_security_group_id" {
  description = "Public security group ID"
  type        = string
}

variable "private_security_group_id" {
  description = "Private security group ID"
  type        = string
}

variable "s3_data_bucket_arn" {
  description = "ARN of the S3 data bucket for ECS access"
  type        = string
}

# variable "rds_cluster_resource_id" {
#   description = "RDS cluster resource ID for IAM authentication"
#   type        = string
# }

variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "nginx:latest"
}

variable "backend_image" {
  description = "Backend container image to deploy"
  type        = string
  default     = "959959864795.dkr.ecr.ap-south-1.amazonaws.com/jarwiz-acr:backend-manual-v1"
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 512
}

variable "backend_task_cpu" {
  description = "CPU units for the backend task"
  type        = number
  default     = 512
}

variable "backend_task_memory" {
  description = "Memory for the backend task in MiB"
  type        = number
  default     = 1024
}

variable "service_desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

variable "service_min_count" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "service_max_count" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "backend_service_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

variable "container_environment" {
  description = "Environment variables for the container"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "backend_environment" {
  description = "Environment variables for the backend container"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "container_secrets" {
  description = "Secrets for the container"
  type        = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "backend_secrets" {
  description = "Secrets for the backend container"
  type        = list(object({
    name      = string
    value     = optional(string)
    valueFrom = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "key_name" {
  description = "Name of the key pair to use for EC2 instances"
  type        = string
}

variable "callsense_image" {
  description = "Docker image for callsense service"
  type        = string
  default     = ""
}

variable "callsense_task_cpu" {
  description = "CPU units for callsense task"
  type        = number
  default     = 512
}

variable "callsense_task_memory" {
  description = "Memory for callsense task in MiB"
  type        = number
  default     = 1024
}

variable "callsense_service_desired_count" {
  description = "Desired count of callsense service tasks"
  type        = number
  default     = 1
}

variable "callsense_environment" {
  description = "Environment variables for callsense container"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "callsense_secrets" {
  description = "Secrets for callsense container"
  type        = list(object({
    name      = string
    valueFrom = string
  }))
  default     = []
}