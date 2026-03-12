resource "aws_s3_bucket" "athena" {
  bucket = "mdekort.athena"
}

resource "aws_s3_bucket_acl" "athena" {
  bucket = aws_s3_bucket.athena.id

  acl = "private"
}

resource "aws_s3_bucket_public_access_block" "athena" {
  bucket = aws_s3_bucket.athena.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena" {
  bucket = aws_s3_bucket.athena.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_alias.generic.arn
    }
  }
}

resource "aws_athena_database" "mdekort" {
  name   = "mdekort"
  bucket = aws_s3_bucket.athena.bucket

  encryption_configuration {
    encryption_option = "SSE_KMS"
    kms_key           = aws_kms_key.generic.arn
  }
}
