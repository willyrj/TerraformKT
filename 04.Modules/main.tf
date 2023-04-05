# Create a GCS Bucket
# resource "google_storage_bucket" "tf-bucket" {
#   project       = var.gcp_project
#   name          = var.bucket-name
#   location      = var.gcp_region
#   force_destroy = true
#   storage_class = var.storage-class
#   versioning {
#     enabled = true
#   }
# }

module "bucket01" {
source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
version = "~> 3.4"
name = "mybucket2021superduper"
project_id = var.gcp_project
location = var.gcp_region
}

module "bucket02"{
  source= "./modules/storage_buckets"
  name = "mybucket2021otherduper"
  project_id = var.gcp_project
  location = var.gcp_region
  storage_class= var.storage-class
  force_destroy = true
}