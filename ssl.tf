data "aws_acm_certificate" "ssl_certificate" {
  domain      = var.domain_name
  most_recent = true
  statuses    = ["ISSUED"]
}

# resource "aws_lb_listener" "http_listener" {
#   load_balancer_arn = aws_lb.webapp_lb.arn
#   port              = 443
#   protocol          = "HTTPS"

#   ssl_policy      = "ELBSecurityPolicy-2016-08"
#   certificate_arn = data.aws_acm_certificate.ssl_certificate.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.webapp_tg.arn
#   }
# }