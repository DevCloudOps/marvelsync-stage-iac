output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

# output "service_id" {
#   description = "The ID of the ECS service"
#   value       = aws_ecs_service.app.id
# }

# output "service_name" {
#   description = "The name of the ECS service"
#   value       = aws_ecs_service.app.name
# }

output "backend_service_id" {
  description = "The ID of the backend ECS service"
  value       = aws_ecs_service.backend.id
}

output "backend_service_name" {
  description = "The name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.ecs.dns_name
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.ecs.arn
}

# output "target_group_arn" {
#   description = "The ARN of the target group"
#   value       = aws_lb_target_group.ecs.arn
# }

output "backend_target_group_arn" {
  description = "The ARN of the backend target group"
  value       = aws_lb_target_group.backend.arn
}

output "task_execution_role_arn" {
  description = "The ARN of the task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "The ARN of the task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
} 

output "ecs_security_group_id" {
  description = "The ID of the ECS security group"
  value       = aws_security_group.ecs_instances.id
}