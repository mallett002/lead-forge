# This defines a cloudfront distribution for the api
# - WAF -> cloudfront -> api-gateway -> lambdas
# - origin is api-gateway
# - alias is api.farmtotablenearme.com
# - caching is disabled
# - only accessible USA & Brazil
# - example: https://github.com/aws-samples/integrate-httpapi-with-cloudfront-and-waf/blob/main/cloudfront.tf


resource "aws_cloudfront_distribution" "api" {
  enabled = true

  # Put the WAF in front of this CF distrabution
  web_acl_id = aws_wafv2_web_acl.api-cloudfront-waf.arn

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
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    viewer_protocol_policy = "redirect-to-https"

    # Managed - AllViewer Request policy (allows query strings to be passed through): https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html#managed-origin-request-policy-all-viewer
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      # Allow only United States and Brazil
      locations = ["US", "BR"]
    }
  }
}
