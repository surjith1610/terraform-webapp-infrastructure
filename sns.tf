resource "aws_sns_topic" "user_verification_topic" {
  name = var.sns_topic_name
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.user_verification_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.user_verification_lambda.arn

  depends_on = [aws_lambda_function.user_verification_lambda]
}