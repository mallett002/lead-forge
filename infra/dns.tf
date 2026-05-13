# 1. aws_acm_certificate — You request a cert, AWS generates validation DNS records (stored in domain_validation_options)
# 2. aws_route53_record.cert_validation — Terraform reads those generated options and creates actual DNS records in Route53 (TXT or CNAME records)
# 3. AWS checks — AWS periodically checks your DNS for those records to prove you own the domain
# 4. aws_acm_certificate_validation — Waiter that blocks until status = "Issued"
# So cert_validation doesn't "validate" itself — it creates the DNS records that AWS then checks.
# The actual validation is done by AWS reading those DNS records.

# The cert for farmtotablenearme.com
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1 # All tf resources accept this. Cloudfront needs to be in us-east-1
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${var.domain_name}",
    "api.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Alias record for root dns -> cloudfront
resource "aws_route53_record" "site-alias-record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront-distro.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront-distro.hosted_zone_id
    evaluate_target_health = false
  }
}

# alias record for subdomain (www.)
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront-distro.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront-distro.hosted_zone_id
    evaluate_target_health = false
  }
}

# Validate the certs automatically through DNS
# Creates TXT/CNAME records that ACM checks for domain ownership
# Could technically delete them after validation finished, but harmless
# example for how this works: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

# Alias record for cloudfront -> api gateway (api.)
# Note - We are sharing the cert for cloudfront and api gateway
# This isn't always best, i.e., if you want to have api gateway in other region that us-east-1 
# (cloudfront needs to be in us-east-1)
resource "aws_route53_record" "api_alias_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
    evaluate_target_health = false
  }
}

# Wait for DNS validation to complete before cert is "Issued"
# Blocks Terraform until ACM status = Issued
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
