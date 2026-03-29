resource "aws_dynamodb_table" "leads-dynamodb-table" {
  name           = "leads"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"
  range_key      = "createdAt"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  tags = {
    Name = "lead-forge"
  }
}
