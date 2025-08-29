# Jarwiz Infrastructure as Code

![Infrastructure Diagram](./infrastructure-diagram.png)

This Terraform configuration creates a complete AWS infrastructure with VPC, S3 (data only), ECS, and RDS MySQL in the Mumbai (ap-south-1) region.

## Architecture Overview

The infrastructure includes:

- **VPC** with public and private subnets across multiple availability zones (ap-south-1a as primary)
- **S3** bucket for application data storage
- **RDS MySQL** instance in private subnets
- **ECS Fargate** cluster with auto-scaling and load balancer
- **Application Load Balancer** for routing traffic to ECS
- **CloudWatch** for logging and monitoring
- **Firebase** integration (external)
- **CDN (Fastly)** and DNS (GoDaddy) for frontend static assets (external)

## Prerequisites

- Terraform >= 1.5.7
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd jarwiz-iac
   ```

2. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

## Module Structure

```
modules/
├── vpc/          # VPC, subnets, security groups, route tables
├── s3/           # S3 bucket for data storage
├── rds/          # RDS MySQL instance
└── ecs/          # ECS cluster, services, and load balancer
```

## Configuration

### Required Variables

- `aws_region`: AWS region for deployment (default: ap-south-1)
- `project_name`: Name of the project
- `environment`: Environment name (dev, staging, prod)
- `db_password`: Database password (sensitive)

### Optional Variables

- `vpc_cidr`: VPC CIDR block (default: 10.0.0.0/16)
- `instance_type`: EC2 instance type (default: t3.micro)
- `db_instance_class`: RDS instance class (default: db.t3.micro)

## Infrastructure Components

### VPC Module
- Creates VPC with DNS support in ap-south-1 region
- Public subnets in ap-south-1a and ap-south-1b with auto-assign public IPs
- Private subnets for database and application servers
- Internet Gateway for public subnets
- NAT Gateway for private subnet internet access
- Security groups for public and private access

### S3 Module
- **Data Bucket**: Application data storage with versioning and encryption
- IAM policies for S3 access
- Public access blocking for data bucket

### RDS Module
- MySQL instance in private subnets
- Enhanced monitoring
- Automated backups and maintenance windows
- Security group allowing access from private subnets

### ECS Module
- Fargate cluster with container insights
- Application load balancer in public subnets
- Auto-scaling based on CPU and memory utilization
- CloudWatch logging
- Task execution and task roles

## Outputs

The configuration provides comprehensive outputs including:

- VPC and subnet IDs
- S3 bucket names and ARNs (data only)
- RDS instance endpoints
- ECS cluster and service information
- Infrastructure summary

## Security Features

- Private subnets for sensitive resources
- Security groups with minimal required access
- S3 bucket encryption and appropriate public access controls
- RDS in private subnets with encrypted connections
- IAM roles with least privilege access

## Cost Optimization

- Uses t3.micro instances for development
- S3 versioning for data protection
- Auto-scaling to optimize resource usage
- RDS instance scheduling (can be added)

## Maintenance

### Updating Infrastructure
```bash
terraform plan
terraform apply
```

### Destroying Infrastructure
```bash
terraform destroy
```

### Adding New Modules
1. Create module directory in `modules/`
2. Add module call to `main.tf`
3. Add outputs to `output.tf`
4. Update documentation

## Troubleshooting

### Common Issues

1. **VPC Dependency Errors**: Ensure VPC module is created before other modules
2. **S3 Bucket Naming**: Bucket names must be globally unique
3. **RDS Password**: Must meet AWS RDS password requirements
4. **IAM Permissions**: Ensure AWS credentials have necessary permissions

### Useful Commands

```bash
# View outputs
terraform output

# View specific output
terraform output vpc_id

# Refresh state
terraform refresh

# Import existing resources
terraform import module.vpc.aws_vpc.main vpc-12345
```

## Contributing

1. Follow Terraform best practices
2. Add appropriate documentation
3. Test changes with `terraform plan`
4. Update outputs for new resources

## License

[Add your license information here]