output "instance_identifier" {
  description = "The instance identifier"
  value       = aws_db_instance.mysql.identifier
}

output "cluster_endpoint" {
  description = "The database endpoint"
  value       = aws_db_instance.mysql.endpoint
}

output "cluster_reader_endpoint" {
  description = "The database endpoint (same as primary for single instance)"
  value       = aws_db_instance.mysql.endpoint
}

output "cluster_port" {
  description = "The port on which the DB accepts connections"
  value       = aws_db_instance.mysql.port
}

output "database_name" {
  description = "The name of the database"
  value       = aws_db_instance.mysql.db_name
}

output "master_username" {
  description = "The master username for the database"
  value       = aws_db_instance.mysql.username
}

output "cluster_resource_id" {
  description = "The Resource ID of the instance"
  value       = aws_db_instance.mysql.resource_id
}

output "cluster_arn" {
  description = "The ARN of the instance"
  value       = aws_db_instance.mysql.arn
}

output "security_group_id" {
  description = "The security group ID"
  value       = aws_security_group.rds-mysql-sg.id
}

output "subnet_group_name" {
  description = "The subnet group name"
  value       = aws_db_subnet_group.mysql.name
} 