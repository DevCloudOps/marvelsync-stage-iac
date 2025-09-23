# RDS Subnet Group
resource "aws_db_subnet_group" "mysql" {
  name       = "${var.project_name}-${var.environment}-mysql-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mysql-subnet-group"
  })
}

# RDS Security Group
resource "aws_security_group" "rds-mysql-sg" {
  name_prefix = "${var.project_name}-${var.environment}-mysql-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.private_security_group_id]
  }

  # Allow access from ECS security group
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_nat_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mysql-sg"
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "mysql" {
  family = "mysql8.0"
  name   = "${var.project_name}-${var.environment}-mysql-params"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mysql-params"
  })
}

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier = "${var.project_name}-${var.environment}-mysql"

  engine         = "mysql"
  engine_version = "8.0.40"
  instance_class = var.db_instance_class

  allocated_storage     = 100
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.snapshot_identifier == null ? var.db_name : null
  username = var.snapshot_identifier == null ? var.db_username : null
  password = var.snapshot_identifier == null ? var.db_password : null

  vpc_security_group_ids = [aws_security_group.rds-mysql-sg.id]
  db_subnet_group_name   = aws_db_subnet_group.mysql.name

  parameter_group_name = aws_db_parameter_group.mysql.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  snapshot_identifier = var.snapshot_identifier
  skip_final_snapshot = var.skip_final_snapshot

  deletion_protection = false

  performance_insights_enabled = false
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mysql"
  })
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role Policy Attachment for RDS Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
} 
