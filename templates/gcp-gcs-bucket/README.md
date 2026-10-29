# gcp-gcs-bucket

Creates a private Cloud Storage bucket with uniform bucket-level access, public access prevention enforced and object versioning on. Noncurrent versions are deleted after 30 days by default. `force_destroy` is on, so a destroy also removes the objects.

Attach a GCP cloud connector and set `project_id`. Every other input has a default.

| Output | Description |
|---|---|
| `bucket_name` | Name of the bucket |
| `bucket_url` | `gs://` URL of the bucket |
