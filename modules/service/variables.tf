variable "name" {
  description = "Service name."
  type        = string
}

variable "environment" {
  description = "Environment the service runs in."
  type        = string
}

variable "image_tag" {
  description = "Container image tag to deploy."
  type        = string
}

variable "replica_count" {
  description = "Desired number of running tasks."
  type        = number

  validation {
    condition     = var.replica_count >= 1
    error_message = "replica_count must be at least 1."
  }
}

variable "cpu" {
  description = "CPU units per task."
  type        = number
}

variable "memory" {
  description = "Memory (MiB) per task."
  type        = number
}

variable "autoscaling_max" {
  description = "Upper bound for autoscaling."
  type        = number
}

variable "db_engine" {
  description = "Database engine."
  type        = string
}

variable "db_engine_version" {
  description = "Major database engine version. A major upgrade replaces the database."
  type        = string
}

variable "db_instance_class" {
  description = "Database instance class."
  type        = string
}

variable "db_multi_az" {
  description = "Run the database with a standby in a second AZ."
  type        = bool
}

variable "healthy_targets" {
  description = "Targets reporting healthy after the rollout, as reported by the load balancer."
  type        = number
}

variable "min_healthy_targets" {
  description = "Minimum healthy targets for the rollout check to pass."
  type        = number
}

variable "rollout_check_script" {
  description = "Path to the rollout check script."
  type        = string
}

variable "public_ingress" {
  description = "Accept traffic on the load balancer from the internet instead of the internal network only."
  type        = bool
  default     = false
}

variable "internal_cidrs" {
  description = "Internal ranges allowed to reach the load balancer when public_ingress is false."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "tags" {
  description = "Tags applied to every object."
  type        = map(string)
  default     = {}
}
