data "google_compute_network" "prueba" {
  project = var.project_id
  name ="dev-network"
}

module "gke_fw_rules" {
  source     = "../modules/net-vpc-firewall"
  project_id = var.project_id
  network    = data.google_compute_network.prueba.name
  default_rules_config = {
    ssh_ranges = ["10.0.0.0/8"]
    ssh_tags=["ssh-default"]
  }
}
