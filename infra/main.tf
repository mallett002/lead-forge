resource "aws_s3_bucket" "lead-forge-website-s3-bucket" {
  bucket = "lead-forge-website-s3-bucket"

  tags = {
    Name = "lead-forge"
  }
}
