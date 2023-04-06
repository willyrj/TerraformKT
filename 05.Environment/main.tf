# define GCP region
variable "gcp_region" {
  type        = string
  description = "GCP region"
  default     = "us-central1"
}
# define GCP project name
variable "gcp_project" {
  type        = string
  description = "GCP project name"
  default     = "hub01-379813"
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


# VPC Subnet VM
# Create VPC and Subnet
#https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance

resource "google_compute_network" "gke_vpc" {
  name                    = "test-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnets" {
  name          = "test-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.gcp_region
  network       = google_compute_network.custom-test.id
  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.custom-test.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges=["0.0.0.0/0"]
}


# VM
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_service_account" "default" {
  account_id   = "serviceaccountid"
  display_name = "Service Account"
}

resource "google_compute_instance" "default" {
  name         = "test"
  machine_type = "e2-medium"
  zone         = "us-central1-c"

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = google_compute_network.custom-test.name
    subnetwork=google_compute_subnetwork.subnets.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }
}