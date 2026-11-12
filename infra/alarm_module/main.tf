resource "aws_sns_topic" "alarms" {
  name = "${var.prefix}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_metric_alarm" "bedrock_latency" {
  alarm_name        = "${var.prefix}-bedrock-p90-latency"
  alarm_description = "p90 for Bedrock-svartid er over terskelen i flere perioder på rad"
  namespace         = var.metrics_namespace
  metric_name       = "wishifai.bedrock.latency.percentile.value"
  dimensions = {
    phi = "0.9"
  }
  statistic           = "Maximum"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold_ms
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
}