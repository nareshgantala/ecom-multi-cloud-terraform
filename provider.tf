terraform {
  backend "gcs" {
    bucket = "nareshgantala-roboshop-gcp"
    prefix = "dev"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.0.0"
    }
  }
}




provider "google" {
  project = "project-b30e4ed9-1852-43c5-bfc"
  region  = "us-west1"
  zone    = "us-west1-a"
}
