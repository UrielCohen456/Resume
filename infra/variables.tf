variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket that hosts the website"
  type        = string
  default = "uriel-resume-challenge"
}

variable "dynamodb_table_name" {
  description = "Name of the table that hosts the counter record for website visits"
  type        = string
  default = "visitor-counter"
}
