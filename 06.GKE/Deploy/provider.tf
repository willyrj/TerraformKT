terraform {
  required_version = ">= 1.3.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.55.0" # tftest
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.55.0" # tftest
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
  }
}
