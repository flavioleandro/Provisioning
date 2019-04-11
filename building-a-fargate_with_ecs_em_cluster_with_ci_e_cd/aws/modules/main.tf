# Configure the provider
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIARMEROPMAZGTTDKPB"
  secret_key = "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"
}

# Create s3 bucket to store tfstate files 
resource "aws_s3_bucket" "terraform-storage-fargate-s3" {
  bucket = "terraform-storage-fargate-s3"

  versioning {
      enabled = true
  }

  lifecycle {
      prevent_destroy = true
  }

  tags {
      Name = "S3 Remote Terraform State Store"
  }      
}