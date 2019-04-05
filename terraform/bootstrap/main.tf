provider "aws" {
  region = "${var.aws_region}"
  version = "~> 2.0"
}

# S3 bucket for storing state
resource "aws_s3_bucket" "tf_backend_state" {
  bucket        = "${var.bucket}"
  region        = "${var.aws_region}"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# DynamoDB table for state locking and consistency
resource "aws_dynamodb_table" "tf_backend_statelock" {
  name           = "${var.dynamodb_table}"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
