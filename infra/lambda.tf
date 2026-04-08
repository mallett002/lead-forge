# iam policy - Who can assume a role
data "aws_iam_policy_document" "policy_lambda_exec_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# lambda exec role - what the lambda can do
resource "aws_iam_role" "lambda-execution-role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.policy_lambda_exec_role.json
}

# Attach permissions to Lambda role (what the execution role can do)
resource "aws_iam_role_policy" "lambda_execution_role_policy" {
  name = "lambda-cloudwatch-logs"
  role = aws_iam_role.lambda-execution-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = aws_dynamodb_table.leads-dynamodb-table.stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = aws_ses_email_identity.ses-sender.arn
      }
    ]
  })
}

# triggered off of change in leads table
resource "aws_lambda_event_source_mapping" "dynamo_stream" {
  event_source_arn  = aws_dynamodb_table.leads-dynamodb-table.stream_arn
  function_name = aws_lambda_function.leads_stream_lambda.arn
  starting_position = "LATEST"

  tags = {
    Name = "lead-forge"
  }
}

# Lambda function running Go binary from bootstrap; assumes lambda-execution-role
resource "aws_lambda_function" "leads_stream_lambda" {
  function_name = "leads-stream-lambda"

  filename         = "${path.module}/../lambdas/leads-events/function.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/leads-events/function.zip")

  handler = "bootstrap"
  runtime = "provided.al2"

  # lambda assumes this role when it runs
  role = aws_iam_role.lambda-execution-role.arn
}
