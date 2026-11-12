locals {
  metrics_namespace = "wishifai-${var.candidate_number}"
  service_name      = "wishifai-${var.candidate_number}"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "wishifai-${var.candidate_number}"

  dashboard_body = jsonencode({
    start          = "2026-11-11T21:00:00.000Z"
    end            = "2026-11-12T08:00:00.000Z"
    periodOverride = "inherit"
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6
        properties = {
          title                = "gaveforslag per analyse (snitt)"
          view                 = "singleValue"
          region               = var.region
          stat                 = "Average"
          setPeriodToTimeRange = true
          metrics = [
            [local.metrics_namespace, "wishifai.suggestions.per_request.avg"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 6
        properties = {
          title                = "antall analyser"
          view                 = "singleValue"
          region               = var.region
          stat                 = "Sum"
          setPeriodToTimeRange = true
          metrics = [
            [local.metrics_namespace, "wishifai.suggestions.per_request.count"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "svartid: median og p90 (ms)"
          view   = "timeSeries"
          region = var.region
          stat   = "Maximum"
          period = 600
          metrics = [
            [local.metrics_namespace, "http.server.requests.percentile.value", "exception", "none", "phi", "0.5", "method", "POST", "error", "none", "uri", "/api/analyze", "outcome", "SUCCESS", "status", "200", { label = "Totalt (median)" }],
            [local.metrics_namespace, "http.server.requests.percentile.value", "exception", "none", "phi", "0.9", "method", "POST", "error", "none", "uri", "/api/analyze", "outcome", "SUCCESS", "status", "200", { label = "Totalt (p90)" }],
            [local.metrics_namespace, "wishifai.bedrock.latency.percentile.value", "phi", "0.5", { label = "Bedrock (median)" }],
            [local.metrics_namespace, "wishifai.rekognition.latency.percentile.value", "phi", "0.5", { label = "Rekognition (median)" }],
            [local.metrics_namespace, "wishifai.s3.upload.latency.percentile.value", "phi", "0.5", { label = "S3 (median)" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS: CPU og minne"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "default", "ServiceName", local.service_name, { label = "CPU %" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "default", "ServiceName", local.service_name, { label = "Minne %" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS: kjørende tasks"
          view   = "timeSeries"
          region = var.region
          stat   = "Maximum"
          period = 60
          metrics = [
            ["AWS/ECS", "LiveTaskCount", "ClusterName", "default", "ServiceName", local.service_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "JVM heap (bytes)"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 60
          metrics = [
            [local.metrics_namespace, "jvm.memory.used.value", "area", "heap", "id", "Eden Space", { label = "Eden Space" }],
            [local.metrics_namespace, "jvm.memory.used.value", "area", "heap", "id", "Tenured Gen", { label = "Tenured Gen" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "JVM prosess-CPU"
          view   = "timeSeries"
          region = var.region
          stat   = "Average"
          period = 60
          metrics = [
            [local.metrics_namespace, "process.cpu.usage.value"]
          ]
        }
      }
    ]
  })
}