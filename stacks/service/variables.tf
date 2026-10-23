variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "image_tag" {
  description = "checkout-api image tag to deploy."
  type        = string
  default     = "1.42.0"
}

variable "replica_count" {
  description = "Desired checkout-api tasks."
  type        = number
  default     = 3
}

variable "db_engine_version" {
  description = "Major PostgreSQL version. Changing it replaces the database."
  type        = string
  default     = "15"
}

variable "db_instance_class" {
  description = "Database instance class."
  type        = string
  default     = "db.r6g.large"
}

variable "healthy_targets" {
  description = "Healthy targets reported by the load balancer after the rollout."
  type        = number
  default     = 3
}

variable "min_healthy_targets" {
  description = "Minimum healthy targets for the rollout check to pass."
  type        = number
  default     = 2
}

variable "change_freeze" {
  description = "Set to true during a change freeze. Any plan against this stack then fails."
  type        = bool
  default     = false
}
