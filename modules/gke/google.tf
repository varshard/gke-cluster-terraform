terraform {
  backend "gcs" {
    bucket = "varshard"
    prefix = "terraform"
    credentials = "account.json"
  }
}

provider "google" {
  credentials = var.credentials
  project     = var.project
  region      = var.region
}

data "google_client_config" "current" {}

output "project" {
  value = data.google_client_config.current.project
}
