# SES
# triggered from lambda from dynamodb streams
# gets email logo from lead-forge-assest s3 bucket
# uses html template and adds logo
# sends email


# allow lambda to send email via ses (exec role)
resource "aws_ses_email_identity" "ses-sender" {
  email = "mallett002@gmail.com"
}

resource "aws_ses_template" "lead-forge-verification" {
  name    = "lead-forge-verification"
  subject = "Greetings, {{name}}!"
  html    = "<h1>Hello {{name}}!</h1>"
  text    = "Hello {{name}},\r\n How you doing?."
}
