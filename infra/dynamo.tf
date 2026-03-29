resource "aws_dynamodb_table" "leads-dynamodb-table" {
  name           = "leads"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"
  range_key      = "createdAt"

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
