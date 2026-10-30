variable "region" {
  description = "AWS-region for alle ressurser"
  type        = string
  default     = "eu-west-1"
}

variable "candidate_number" {
  description = "Kandidatnummer, brukes i ressursnavn for å gjøre dem unike"
  type        = string
  default     = "54"
}

variable "image_tag" {
  description = "Tag på container-imaget i ECR som skal deployes"
  type        = string
  default     = "latest"
}

variable "ecr_repository" {
  description = "Navn på ECR-repo"
  type        = string
  default     = "wishifai-54"
}
