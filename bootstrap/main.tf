# S3 bucket for Terraform state
resource "aws_s3_bucket" "lead-forge-terraform-state-bucket" {
  bucket = "lead-forge-terraform-state-bucket"

  tags = {
    Name = "lead-forge"
  }
}

# Enable versioning to preserve previous versions of the state file.
# This allows recovery if the state file is accidentally overwritten or corrupted.
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.lead-forge-terraform-state-bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to the bucket to prevent sensitive Terraform state
# (which may contain secrets or resource IDs) from being exposed publicly.
resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket = aws_s3_bucket.lead-forge-terraform-state-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for Terraform locks
# Puts a lock on tf state so only 1 apply statement can run at a time
resource "aws_dynamodb_table" "lead_forge_terraform_locks_table" {
  name         = "lead_forge_terraform_locks_table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
