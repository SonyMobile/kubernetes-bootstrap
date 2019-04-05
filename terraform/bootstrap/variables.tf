variable "aws_region" {
  description = "The region on the S3 bucket"
}

variable "bucket" {
  description = "The name of the S3 bucket"
}

variable "dynamodb_table" {
  description = "The name of the DynamoDB table to use for state locking and consistency"
}
