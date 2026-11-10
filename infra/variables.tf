variable "region" {
  description = "AWS-region for alle ressurser"
  type        = string
  default     = "eu-west-1"
}

variable "candidate_number" {
  description = "kandidatnummer"
  type        = string
  default     = "54"
}

variable "image_tag" {
  description = "tag på container-imaget i ECR som skal deployes"
  type        = string
  default     = "latest"
}

variable "ecr_repository" {
  description = "navn på ECR-repo"
  type        = string
  default     = "wishifai-54"
}
