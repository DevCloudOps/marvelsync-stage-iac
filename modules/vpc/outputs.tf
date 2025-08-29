output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.public.id
}

output "private_security_group_id" {
  description = "The ID of the private security group"
  value       = aws_security_group.private.id
}

output "vpc_endpoints_security_group_id" {
  description = "The ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}
