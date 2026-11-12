module "alarm" {
  source            = "./alarm_module"
  prefix            = "wishifai-${var.candidate_number}"
  alarm_email       = var.alarm_email
  metrics_namespace = local.metrics_namespace
}

output "alarm_name" {
  description = "navn på alarmen for Bedrock-svartid"
  value       = module.alarm.alarm_name
}