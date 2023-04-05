resource "google_compute_instance" "default" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

   boot_disk {
    initialize_params {
      image = var.image
    }
  }

  // Local SSD disk
#   scratch_disk {
#     interface = "SCSI"
#   }

  network_interface {
    network = var.network
  }

  # metadata_startup_script = var.metadata_startup_script

  allow_stopping_for_update = var.allow_stopping_for_update

}