# This defines a cloudfront distribution for the api

# example: https://github.com/aws-samples/integrate-httpapi-with-cloudfront-and-waf/blob/main/cloudfront.tf

# TODO: ADD WAF with cloudfront

resource "aws_cloudfront_distribution" "api" {
  enabled = true

  origin {
    domain_name = "${aws_apigatewayv2_api.http_api.id}.execute-api.us-east-1.amazonaws.com"
    origin_id   = "http_api_origin"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  aliases = [
    "api.${var.domain_name}"
  ]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = "http_api_origin"

    # uses CachingDisabled: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      # Allow only United States and Brazil
      locations        = ["US", "BR"]
    }
  }
}
