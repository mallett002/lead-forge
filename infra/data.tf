data "aws_route53_zone" "main" {
  name         = "farmtotablenearme.com"
  private_zone = false
}
