output "alarm_name" {
  description = "navn på alarm"
  value       = aws_cloudwatch_metric_alarm.bedrock_latency.alarm_name
}

output "sns_topic_arn" {
  description = "ARN for SNS-topic som sender varsel"
  value       = aws_sns_topic.alarms.arn
}