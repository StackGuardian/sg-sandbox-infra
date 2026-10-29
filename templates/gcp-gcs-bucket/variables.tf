variable "project_id" {
  description = "ID of the Google Cloud project to create the bucket in."
  type        = string
}

variable "region" {
  description = "Google Cloud region, used as the bucket location."
  type        = string
  default     = "us-central1"
}

variable "bucket_prefix" {
  description = "Prefix for the bucket name. A random suffix is added to keep the name globally unique."
  type        = string
  default     = "sgsandbox"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,38}[a-z0-9]$", var.bucket_prefix))
    error_message = "bucket_prefix must be 3-40 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "noncurrent_version_retention_days" {
  description = "Days to keep a noncurrent object version before it is deleted."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_retention_days >= 1
    error_message = "noncurrent_version_retention_days must be at least 1."
  }
}
