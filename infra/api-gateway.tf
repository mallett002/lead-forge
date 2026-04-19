# domain api.farmtotablenearme.com
# endpoint: POST /leads (creates new lead)
# endpoint: POST /leads/verify (verifies lead)
# endpoint: DELETE /leads/{email} ??

# TODO: Add a WAF (aws_wafv2_web_acl)??

# ****************************************************
# The API Container
# ****************************************************
resource "aws_apigatewayv2_api" "http_api" {
  name          = "v2-lambda-api"
  protocol_type = "HTTP"

  # allow farmtotablenearme.com to make POST requests
  cors_configuration {
    allow_origins = ["https://farmtotablenearme.com"]
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
  }
}

# The Stage (To make it live)
resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

# ****************************************************
# Lambda Integrations
# ****************************************************

# Create lead handler ********************************
# The Integration (Connecting API to Lambda)
# resource "aws_apigatewayv2_integration" "create_lead_integration" {
#   api_id           = aws_apigatewayv2_api.http_api.id
#   integration_type = "AWS_PROXY"
#
#   description               = "Handler for creating a lead"
#   integration_method        = "POST"
#   payload_format_version    = "2.0"
#   integration_uri           = aws_lambda_function.create_lead_lambda.invoke_arn # TODO: Create lambda
# }
#
# # The Route (endpoint for creating lead)
# resource "aws_apigatewayv2_route" "create_leads_route" {
#   api_id    = aws_apigatewayv2_api.http_api.id
#   route_key = "POST /leads"
#   target    = "integrations/${aws_apigatewayv2_integration.create_lead_integration.id}"
# }
#
# # Allow APIGW to trigger Lambda
# resource "aws_lambda_permission" "lambda_permission_create_lead" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.create_lead_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#
#   # only allow POST /leads to trigger lambda
#   source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/POST/leads"
# }

output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
