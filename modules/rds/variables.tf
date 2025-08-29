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

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "private_security_group_id" {
  description = "Private security group ID"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ECS security group ID for database access"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "jarwizdb"
}

variable "create_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "snapshot_identifier" {
  description = "The snapshot ID to restore from"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot"
  type        = bool
  default     = false
}