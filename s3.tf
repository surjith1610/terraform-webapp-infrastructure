resource "random_uuid" "bucket_uuid" {}

# S3 Bucket Configuration
resource "aws_s3_bucket" "webapp_bucket" {
  bucket        = random_uuid.bucket_uuid.result
  force_destroy = true # Allows Terraform to delete non-empty bucket
}

# Make the bucket private
resource "aws_s3_bucket_public_access_block" "webapp_bucket_access" {
  bucket = aws_s3_bucket.webapp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Lifecycle rule for transitioning objects to STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    id     = "transition_to_standard_ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
