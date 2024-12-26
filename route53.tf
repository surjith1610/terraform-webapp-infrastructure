# Route53 Configuration
data "aws_route53_zone" "selected" {
  name = var.domain_name
}

# Creating A record
resource "aws_route53_record" "webapp" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain_name
  type    = "A"
  # ttl     = "300"
  # records = [aws_instance.web_app_instance.public_ip]
  alias {
    name                   = aws_lb.webapp_lb.dns_name
    zone_id                = aws_lb.webapp_lb.zone_id
    evaluate_target_health = true
  }
}