variable "region" {
  description = "AWS region for the bucket."
  type        = string
  default     = "eu-central-1"
}

variable "bucket_prefix" {
  description = "Start of the bucket name. A random suffix is added so the name is globally unique."
  type        = string
  default     = "sg-sandbox"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,45}$", var.bucket_prefix))
    error_message = "bucket_prefix must be 2-46 lowercase letters, digits or hyphens, starting with a letter or digit."
  }
}

variable "versioning_enabled" {
  description = "Keep previous versions of objects."
  type        = bool
  default     = true
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which previous object versions are deleted."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1 && var.noncurrent_version_expiration_days <= 365
    error_message = "noncurrent_version_expiration_days must be between 1 and 365."
  }
}
