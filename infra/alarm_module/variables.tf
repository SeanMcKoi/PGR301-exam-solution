variable "prefix" {
  description = "prefiks for navn på alarm og topic"
  type        = string
}

variable "alarm_email" {
  description = "e-post som får varsel fra alarm"
  type        = string
}

variable "metrics_namespace" {
  description = "CloudWatch-namespace for appens metrikker"
  type        = string
}

variable "threshold_ms" {
  description = "terskel for p90 Bedrock-svartid i ms"
  type        = number
  default     = 30000
}

variable "period_seconds" {
  description = "lengde på hver periode i sekunder"
  type        = number
  default     = 300
}

variable "evaluation_periods" {
  description = "antall perioder på rad over terskel før alarm"
  type        = number
  default     = 3
}