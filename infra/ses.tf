# SES
# triggered from lambda from dynamodb streams
# gets email logo from lead-forge-assest s3 bucket
# uses html template and adds logo
# sends email

# allow lambda to send email via ses (exec role)
resource "aws_ses_email_identity" "ses-sender" {
  email = "your-verified-email@domain.com"
}
