locals {
  s3_bucket_name = "cloud-lab-tfstate-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
}