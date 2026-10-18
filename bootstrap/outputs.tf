output "bucket_name" {
  value       = local.s3_bucket_name
  description = "S3 bucket name for storing Terraform state"
}
output "region" {
  value       = data.aws_region.current.region
  description = "AWS region where the S3 bucket is created"
}