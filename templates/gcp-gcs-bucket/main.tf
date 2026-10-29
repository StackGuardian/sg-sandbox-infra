# A private, versioned bucket. Noncurrent versions expire after a set number
# of days, and the bucket can be destroyed with objects still in it.

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "google_storage_bucket" "this" {
  name          = "${var.bucket_prefix}-${random_string.suffix.result}"
  location      = upper(var.region)
  storage_class = "STANDARD"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      with_state                 = "ARCHIVED"
      days_since_noncurrent_time = var.noncurrent_version_retention_days
    }
    action {
      type = "Delete"
    }
  }

  # Versioning already keeps old copies; skip the extra soft-delete storage.
  soft_delete_policy {
    retention_duration_seconds = 0
  }
}
