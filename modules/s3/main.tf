# Application Data Bucket
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project_name}-${var.environment}-qms"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}"
  })
}

# Static Website Hosting Bucket
resource "aws_s3_bucket" "static_website" {
  bucket = "${var.environment}.jarvisqms.com"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-website"
    Environment = var.environment
  })
}

# Versioning for app data bucket
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning for static website bucket
resource "aws_s3_bucket_versioning" "static_website" {
  bucket = aws_s3_bucket.static_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for app data bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Server-side encryption for static website bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block for app data bucket
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Public access block for static website bucket (allows public read)
resource "aws_s3_bucket_public_access_block" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Static website configuration
resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Bucket policy for static website (allows public read access)
resource "aws_s3_bucket_policy" "static_website" {
  bucket = aws_s3_bucket.static_website.id

  depends_on = [aws_s3_bucket_public_access_block.static_website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website.arn}/*"
      }
    ]
  })
}

# IAM policy for S3 access
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-${var.environment}-s3-access-policy"
  description = "Policy for S3 bucket access"

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
          aws_s3_bucket.app_data.arn,
          "${aws_s3_bucket.app_data.arn}/*"
        ]
      }
    ]
  })
}


# Terraform State Bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-iac-${var.environment}"
  force_destroy = false # Prevents accidental deletion
  
  # Add lifecycle rule to prevent destruction of this critical bucket
  lifecycle {
    prevent_destroy = false
  }
  
  tags = merge(var.tags, {
    Environment = "${var.environment}"
  })
}

# Server-side encryption for Terraform state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block for Terraform state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add CORS configuration for app_data bucket
resource "aws_s3_bucket_cors_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]  # Consider restricting to specific domains in production
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Update or add bucket policy for app_data bucket
resource "aws_s3_bucket_policy" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  
  # This policy depends on the public access block to ensure the settings don't conflict
  depends_on = [aws_s3_bucket_public_access_block.app_data]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAppAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource  = [
          aws_s3_bucket.app_data.arn,
          "${aws_s3_bucket.app_data.arn}/*"
        ]
      }
    ]
  })
}

# Static Website Hosting Bucket
resource "aws_s3_bucket" "audit_workflow_website" {
  bucket = "${var.environment}-audit-workflow.thejarwiz.com"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-website"
    Environment = var.environment
  })
}

# Server-side encryption for static website bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_workflow_website" {
  bucket = aws_s3_bucket.audit_workflow_website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# Public access block for static website bucket (allows public read)
resource "aws_s3_bucket_public_access_block" "audit_workflow_website" {
  bucket = aws_s3_bucket.audit_workflow_website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Static website configuration
resource "aws_s3_bucket_website_configuration" "audit_workflow_website" {
  bucket = aws_s3_bucket.audit_workflow_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Bucket policy for static website (allows public read access)
resource "aws_s3_bucket_policy" "audit_workflow_website" {
  bucket = aws_s3_bucket.audit_workflow_website.id

  depends_on = [aws_s3_bucket_public_access_block.audit_workflow_website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.audit_workflow_website.arn}/*"
      }
    ]
  })
}

# Add CORS configuration for audit_workflow_website bucket
resource "aws_s3_bucket_cors_configuration" "audit_workflow_website" {
  bucket = aws_s3_bucket.audit_workflow_website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]  # Consider restricting to specific domains in production
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}