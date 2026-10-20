provider "aws" {
  profile = "terraform"
  region  = "eu-north-1"

  default_tags {
    tags = {
      Project   = "cloud-lab"
      ManagedBy = "terraform"
    }
  }
}