terraform {
  backend "s3" {
    bucket         = "uriel-resume-challenge-terraform-state" 
    key            = "terraform/state"
    region         = var.region
  }
}
