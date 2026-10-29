# aws-s3-bucket

Creates a private S3 bucket: public access blocked, SSE-S3 (AES256) encryption, versioning, and a lifecycle rule that deletes previous object versions after `noncurrent_version_expiration_days`. The bucket name is `bucket_prefix` plus a random suffix.

`force_destroy` is on, so a destroy run removes the bucket even when it still holds objects.

Needs an AWS cloud connector. Every input has a working default.

| Output | Description |
|---|---|
| `bucket_name` | Name of the bucket |
| `bucket_arn` | ARN of the bucket |
| `region` | Region the bucket is in |
