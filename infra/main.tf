# s3 bucket -> aws_s3_bucket 
# cloudfront distro (with origin to s3) -> aws_cloudfront_distribution
# allow cloudfront to read/write to s3 (probably just read actually) -> aws_cloudfront_origin_access_control, aws_s3_bucket_policy
# route53 hosted zone -> aws_route53_zone (already created this one manualy)
# route53 Alias record (alias = farmtotablenearme.com -> cloudfront's domain) -> aws_route53_record (alias)
# ACM cert (https) -> aws_acm_certificate, aws_acm_certificate_validation

# s3 bucket 
# - private acl, bucket policy
# - index & error html files
# - allow cloudfront distro to read

# cloudfront distro
# - s3 as origin

# route53
# - hosted zone farmtotable
# - A "alias record" farmtotable -> cloudfront url
# - cert
