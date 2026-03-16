# lookup the route_53 hosted zone that was created manually in aws console
data "aws_route53_zone" "main" {
  name         = "farmtotablenearme.com"
  private_zone = false
}
