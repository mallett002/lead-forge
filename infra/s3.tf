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

# upload app to s3
locals {
  dist_files = fileset("${path.module}/../lead-forge-spa/dist", "**")

  content_types = {
    ".html" = "text/html"
    ".js"   = "application/javascript"
    ".css"  = "text/css"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
  }
}

resource "aws_s3_object" "lead-forge-website-files" {
  for_each = { for file in local.dist_files : file => file }

  bucket = aws_s3_bucket.site-bucket.id
  key    = each.value
  source = "${path.module}/../lead-forge-spa/dist/${each.value}"

  etag = filemd5("${path.module}/../lead-forge-spa/dist/${each.value}")

  content_type = lookup(
    local.content_types,
    regex("\\.[^.]+$", each.value),
    "application/octet-stream"
  )

  cache_control = (
    each.value == "index.html"
    ? "no-cache, no-store, must-revalidate"
    : "public, max-age=31536000, immutable"
  )

  lifecycle {
    ignore_changes = [etag]
  }
}
