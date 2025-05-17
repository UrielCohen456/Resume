terraform {
  backend "s3" {
    bucket         = "uriel-resume-challenge-terraform-state" 
    key            = "terraform/state"
    region         = "eu-central-1"
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
}
