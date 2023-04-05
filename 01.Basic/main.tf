# define GCP region
variable "gcp_region" {
  type        = string
  description = "GCP region"
  default     = "europe-west1"
}
# define GCP project name
variable "gcp_project" {
  type        = string
  description = "GCP project name"
  default     = "hub01-379813"
}
variable "bucket-name" {
  type        = string
  description = "The name of the Google Storage Bucket to create"
  default     = "terraform-gcp-devops-test-372212"
}
variable "storage-class" {
  type        = string
  description = "The storage class of the Storage Bucket to create"
  default     = "NEARLINE"
}

terraform {
  required_version = ">= 0.12"
  # backend "gcs" {
  # }
}
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}
# Create a GCS Bucket
resource "google_storage_bucket" "tf-bucket" {
  project       = var.gcp_project
  name          = var.bucket-name
  location      = var.gcp_region
  force_destroy = true
  storage_class = var.storage-class
  versioning {
    enabled = true
  }
}