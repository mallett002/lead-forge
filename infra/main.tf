resource "aws_s3_bucket" "lead-forge-website-s3-bucket" {
  bucket = "lead-forge-website-s3-bucket"

  tags = {
    Name = "lead-forge"
  }
}


resource "aws_s3_bucket_website_configuration" "lead_forge_website" {
  bucket = aws_s3_bucket.lead-forge-website-s3-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Optional: enable versioning (good practice)
resource "aws_s3_bucket_versioning" "lead-forge-website-versioning" {
  bucket = aws_s3_bucket.lead-forge-website-s3-bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Allow full public access (blocked by default)
# Required for static website in s3
resource "aws_s3_bucket_public_access_block" "website-public-block" {
  bucket = aws_s3_bucket.lead-forge-website-s3-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Allow public read at the bucket level
resource "aws_s3_bucket_policy" "lead-forge-website-policy" {
  bucket = aws_s3_bucket.lead-forge-website-s3-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.lead-forge-website-s3-bucket.arn}/*"
      }
    ]
  })
}

# upload index.html file:
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.lead-forge-website-s3-bucket.id
  key    = "index.html"
  source = "../src/index.html"
  content_type = "text/html"
}

# upload error.html file:
resource "aws_s3_object" "error" {
  bucket = aws_s3_bucket.lead-forge-website-s3-bucket.id
  key    = "error.html"
  source = "../src/error.html"
  content_type = "text/html"
}

# print out the url
output "website_url" {
  value = aws_s3_bucket_website_configuration.lead_forge_website.website_endpoint
}

