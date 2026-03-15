output "cloudfront_url" {
  value = aws_cloudfront_distribution.site.domain_name
}
