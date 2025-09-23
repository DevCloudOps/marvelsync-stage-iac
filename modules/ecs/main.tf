# ECS Cluster with EC2 capacity provider
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cluster"
  })
}

# IAM role for EC2 instances to join ECS cluster
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-${var.environment}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach ECS instance role policy
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# IAM instance profile for ECS instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-${var.environment}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# Security group for ECS instances
resource "aws_security_group" "ecs_instances" {
  name        = "${var.project_name}-${var.environment}-ecs-instances-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_lb.id,aws_security_group.callsense_lb.id]
    description = "Allow all inbound traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-instances-sg"
  })
}

# Find the latest ECS-optimized Amazon Linux 2 AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch template for ECS instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-${var.environment}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3a.small"
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ecs_instances.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_ENI=true >> /etc/ecs/ecs.config
    echo ECS_CONTAINER_STOP_TIMEOUT=90s >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CAPACITY_PROVIDERS=true >> /etc/ecs/ecs.config
    EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
      encrypted   = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-${var.environment}-ecs-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for ECS instances
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-${var.environment}-ecs-asg"
  vpc_zone_identifier = var.private_subnet_ids
  min_size         = 1
  max_size         = 3  # Allow temporary additional capacity during updates
  desired_capacity = 1

  health_check_type         = "ELB"
  health_check_grace_period = 90
  default_instance_warmup   = 90
  protect_from_scale_in     = false

  termination_policies = [
    "OldestInstance",      # Terminate oldest instances first
    "OldestLaunchTemplate" # Prefer newer launch template versions
  ]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
      instance_warmup       = 90
    }
  }

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
     desired_capacity,  # Ignore changes to desired capacity
    ]
  }
}

# ECS capacity provider using the Auto Scaling Group
resource "aws_ecs_capacity_provider" "asg" {
  name = "${var.project_name}-${var.environment}-asg-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn
    
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100         
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
      instance_warmup_period    = 90
    }
    managed_termination_protection = "DISABLED"  
  }
}

# Associate capacity provider with the cluster
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.asg.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg.name
    weight            = 1
    base              = 0
  }
}

# Add security group for ALB
resource "aws_security_group" "ecs_lb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Backend API traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })
}

# IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  })
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for ECS Task Execution Role - ECR Access
resource "aws_iam_policy" "ecs_task_execution_ecr_policy" {
  name        = "${var.project_name}-${var.environment}-ecs-task-execution-ecr-policy"
  description = "Policy for ECS task execution role to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach ECR policy to ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_ecr_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ecr_policy.arn
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for ECS Task Role - S3 Access
resource "aws_iam_policy" "ecs_task_s3_policy" {
  name        = "${var.project_name}-${var.environment}-ecs-task-s3-policy"
  description = "Policy for ECS tasks to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_data_bucket_arn,
          "${var.s3_data_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:GetJob",
          "glue:GetJobs",
          "glue:BatchStopJobRun"
        ],
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for ECS Task Role - Secrets Manager Access
resource "aws_iam_policy" "ecs_task_secrets_policy" {
  name        = "${var.project_name}-${var.environment}-ecs-task-secrets-policy"
  description = "Policy for ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

# Attach S3 policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_s3_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_s3_policy.arn
}

# Attach Secrets Manager policy to ECS task role
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_secrets_policy.arn
}

# Attach Secrets Manager policy to ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_secrets_policy.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-logs"
  })
}

# Application Load Balancer - Now only for backend API
resource "aws_lb" "ecs" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_lb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

# Target Group for Backend (Port 8080)
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 60
    matcher             = "200"
    path                = "/api/v1/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 15
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-tg"
  })
}

# ALB Listener for Backend (Port 8080)
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.ecs.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"  

  certificate_arn = "arn:aws:acm:ap-south-1:959959864795:certificate/3fd46b43-e4a4-491b-9258-10e17d4f8f29"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-listener"
  })
}

# Backend Task Definition - Updated for EC2
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "bridge"
  # Removed requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_task_cpu
  memory                   = var.backend_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = var.backend_image
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort     = 0
          protocol      = "tcp"
        }
      ]

      environment = var.backend_environment
      secrets     = var.backend_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "backend"
        }
      }
    
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/api/v1/actuator/health || exit 1"]
        interval    = 60
        timeout     = 10
        retries     = 3
        startPeriod = 90
      }

      essential = true
    }
  ])
  lifecycle {
    ignore_changes = [
      container_definitions,  # Ignore changes to container definitions
    ]
  }
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-task"
  })
}

# Backend ECS Service - Updated to EC2
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-${var.environment}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_service_desired_count
  # launch_type     = "EC2"  # Changed from FARGATE

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8080
  }

  deployment_controller {
    type = "ECS"
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg.name
    weight           = 1
    base            = 0
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  enable_ecs_managed_tags = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.backend]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend-service"
  })

  lifecycle {
    ignore_changes = [
      task_definition,  # Ignore changes to task definition
      desired_count     # Optionally ignore changes to desired count if you manage scaling elsewhere
    ]
  }
}

# Application Load Balancer for CallSense
resource "aws_lb" "callsense" {
  name               = "${var.project_name}-${var.environment}-callsense-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.callsense_lb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-callsense-alb"
  })
}

# Security group for CallSense ALB
resource "aws_security_group" "callsense_lb" {
  name        = "${var.project_name}-${var.environment}-callsense-alb-sg"
  description = "Security group for CallSense ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow CallSense API traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-callsense-alb-sg"
  })
}

# Target Group for CallSense (Port 8081)
resource "aws_lb_target_group" "callsense" {
  name        = "${var.project_name}-${var.environment}-callsense-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 60
    matcher             = "200"
    path                = "/api/v1/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 15
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-callsense-tg"
  })
}

# ALB Listener for CallSense (Port 443)
resource "aws_lb_listener" "callsense" {
  load_balancer_arn = aws_lb.callsense.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"  

  certificate_arn = "arn:aws:acm:ap-south-1:959959864795:certificate/3fd46b43-e4a4-491b-9258-10e17d4f8f29"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.callsense.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-callsense-listener"
  })
}

# CallSense Task Definition - Using bridge networking mode for EC2
resource "aws_ecs_task_definition" "callsense" {
  family                   = "${var.project_name}-${var.environment}-callsense"
  network_mode             = "bridge"
  cpu                      = var.callsense_task_cpu
  memory                   = var.callsense_task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "callsense"
      image = var.callsense_image
      essential = true

      portMappings = [
        {
          containerPort = 8081
          hostPort     = 0  # Dynamic port mapping
          protocol      = "tcp"
        }
      ]

      environment = var.callsense_environment
      secrets     = var.callsense_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "callsense"
        }
      }
    
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8081/api/v1/actuator/health || exit 1"]
        interval    = 60
        timeout     = 10
        retries     = 3
        startPeriod = 90
      }

      essential = true
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-callsense-task"
  })
}

# CallSense ECS Service
resource "aws_ecs_service" "callsense" {
  name            = "${var.project_name}-${var.environment}-callsense"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.callsense.arn
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.callsense.arn
    container_name   = "callsense"
    container_port   = 8081
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg.name
    weight           = 1
    base            = 0
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  enable_ecs_managed_tags = true

  depends_on = [aws_lb_listener.callsense]

  deployment_controller {
    type = "ECS"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-callsense-service"
  })

  lifecycle {
    ignore_changes = [
      task_definition,  
      desired_count     
    ]
  }
}

resource "aws_autoscaling_lifecycle_hook" "ecs_drain" {
  name                    = "${var.project_name}-${var.environment}-drain-hook"
  autoscaling_group_name  = aws_autoscaling_group.ecs.name
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 90

  notification_metadata = jsonencode({
    cluster_name = aws_ecs_cluster.main.name
  })
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}