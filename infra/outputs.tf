output "service_url" {
  description = "Offentlig URL til Wishifai-tjenesten"
  value       = "https://${trimprefix(aws_ecs_express_gateway_service.app.ingress_paths[0].endpoint, "https://")}"
}

output "s3_bucket" {
  description = "S3-bucket for opplastede bilder"
  value       = aws_s3_bucket.uploads.bucket
}

output "task_role_arn" {
  description = "ARN til task-rollen"
  value       = aws_iam_role.task.arn
}

output "image" {
  description = "Container-imaget som er deployet"
  value       = aws_ecs_express_gateway_service.app.primary_container[0].image
}
