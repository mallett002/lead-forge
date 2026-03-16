# s3 bucket for website
resource "aws_s3_bucket" "site-bucket" {
  bucket = "farmtotablenearme-cloudfront-distro"

  tags = {
    Name = "lead-forge"
  }
}

# bucket public access - private
resource "aws_s3_bucket_public_access_block" "bucket-public-access-block" {
  bucket = aws_s3_bucket.site-bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# bucket policy - allow cloudfront to read from bucket
resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.site-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.site-bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cloudfront-distro.arn
          }
        }
      }
    ]
  })
}

# upload index.html to bucket
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site-bucket.id
  key          = "index.html"
  source       = "../src/index.html"
  content_type = "text/html"
}
