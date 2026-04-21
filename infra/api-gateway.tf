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

# give api gateway a custom domain
resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = "api.farmtotablenearme.com"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# Connect api.farmtotablenearme.com to API stage
resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = aws_apigatewayv2_stage.api_gateway_stage.id
}

# ****************************************************
# Lambda Integrations
# ****************************************************

# Create lead handler ********************************
# The Integration (Connecting API to Lambda)
resource "aws_apigatewayv2_integration" "create_lead_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"

  description               = "Handler for creating a lead"
  integration_method        = "POST"
  payload_format_version    = "2.0"
  integration_uri           = aws_lambda_function.create_lead_lambda.invoke_arn
}

# TODO: Get authorizer working before opening api to world
# Since the frontend will generate a JWT, here's the decision:
# Options for your setup:
# Approach	JWT Validation	Effort	Notes
# Cognito + JWT authorizer	Built-in	Low	Cognito handles sign-up/login, frontend gets JWT from Cognito
# Custom JWT + Lambda authorizer	Your Lambda	Medium	Frontend sends JWT, your auth Lambda verifies it
# API Key	None	Lowest	Not real auth (just throttling/some protection)
# My recommendation: Cognito + JWT authorizer
# Reasons:
# - No auth Lambda needed
# - Cognito manages users, password reset, etc.
# - Frontend gets JWT directly from Cognito
# - API Gateway validates JWT automatically
# - You don't need to write auth logic
# Flow:
# 1. Frontend → Cognito (login/signup) → gets JWT
# 2. Frontend → API request with `Authorization: Bearer
resource "aws_apigatewayv2_authorizer" "example" {
  api_id                            = aws_apigatewayv2_api.http_api.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.example.invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "example-authorizer"
  authorizer_payload_format_version = "2.0"
}

# The Route (endpoint for creating lead)
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

