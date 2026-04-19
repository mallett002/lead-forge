# SES
# triggered from lambda from dynamodb streams
# gets email logo from lead-forge-assest s3 bucket
# uses html template and adds logo
# sends email


resource "aws_ses_template" "lead-forge-verification" {
  name    = "lead-forge-verification"
  subject = "Verify your email"
  html = file("${path.module}/templates/verification.html")
  text = "Hello {{name}}, verify here: {{verificationLink}}"
}

# configuation set for tracking and metrics
resource "aws_ses_configuration_set" "config_set" {
  name = "ses_config_set"
  reputation_metrics_enabled = true # Amazon CloudWatch metric. The default value is false
  sending_enabled = true # email sending is enabled or disabled for the configuration set. The default value is true.

  delivery_options {
    tls_policy = "Require"  #If the value is Optional, messages can be delivered in plain text if a TLS connection can't be established. 
  }
}

# domain identity for farmtotablenearme.com
resource "aws_ses_domain_identity" "ses_domain" {
  domain = "farmtotablenearme.com"
}

# DKIM: "Domain Keys for Identified Mail"
# Proves that email sent from your domain really comes from your domain and wasn't tampered with
# mail providers (gmail) look up your public key in DNS to verify
resource "aws_ses_domain_dkim" "ses_dkim" {
  domain = aws_ses_domain_identity.ses_domain.domain
}

# DKIM selectors: CNAME records that point to AWS-hosted public keys used to verify SES-signed emails
resource "aws_route53_record" "ses_dkim_record" {
  count   = length(aws_ses_domain_dkim.ses_dkim.dkim_tokens)
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${aws_ses_domain_dkim.ses_dkim.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.ses_dkim.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "domain_identity_verification" {
  domain = aws_ses_domain_identity.ses_domain.id

  depends_on = [aws_route53_record.ses_dkim_record]
}
