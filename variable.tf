variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "jarwiz"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "medexpert"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24","10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
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
  default     = null
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "jarwiz"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "jarwiz"
    Environment = "medexpert"
    ManagedBy   = "terraform"
  }
}

variable "key_name" {
  description = "The key pair name to use for EC2 instances"
  type        = string
  default     = "medexpert-aws" # Update with your actual key name
}

variable "glue_security_group_id" {
  description = "AWS Glue security group ID for database access"
  type        = string
  default     = "sg-07a24b16118d7aad0"
}