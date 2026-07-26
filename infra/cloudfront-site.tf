# This defines a cloudfront distribution for a static site in s3
# This CF distribution:
# - has domain name of farmtotablenearme.com
# - has origin of s3 (static site)
# - able to access s3 origin without the bucket being public
# - tied to ssl cert for farmtotablenearme.com
# - only allows US and Brazil

# Allow cloudfront to access s3 without making s3 bucket public
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "farmtotablenearme-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # specifies which requests cloudfront signs (authenticates)
  signing_protocol                  = "sigv4"  # how cloudfront signs (authenticates). "sigv4" is the only valid value
}

resource "aws_cloudfront_distribution" "cloudfront-distro" {
  enabled             = true
  default_root_object = "index.html" # which object you want cloudfront to return

  tags = {
    Name = "lead-forge"
  }

  origin {
    domain_name              = aws_s3_bucket.site-bucket.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    # managed cache policy for "Managed-CachingOptimized" (see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  aliases = [
    var.domain_name,
    "www.${var.domain_name}"
  ]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only" # sni-only cloudfront serves cert per-request rather than a dedicated static IP
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      # Allow only United States and Brazil
      locations = ["US", "BR"]
    }
  }
}
