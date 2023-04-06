module "gke_vpc" {
  source     = "../modules/net-vpc"
  project_id = var.project_id
  name       = var.gke_network_name
  subnets = [
    {
      ip_cidr_range = var.gke_cidr_range
      name          = var.gke_subnet_name
      region        = var.region
      secondary_ip_ranges = {
        pods     = var.gke_pods_range
        services = var.gke_services_range
      }
    }
  ]
}

module "gke_nat" {
  source         = "../modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = var.gke_nat_name
  router_network = module.gke_vpc.network.name
  router_create  = true
  router_name = var.gke_router_name
}
module "gke_fw_rules" {
  source     = "../modules/net-vpc-firewall"
  project_id = var.project_id
  network    = var.gke_network_name
  default_rules_config = {
    ssh_ranges = ["10.0.0.0/8"]
    ssh_tags=["ssh-default"]
  }
}

module "myproject-default-service-accounts" {
  source     = "../modules/iam-service-account"
  project_id = var.project_id
  name       = var.jumpbox_sac_name
  # authoritative roles granted *on* the service accounts to other identities
  #   iam = {
  #     "roles/iam.serviceAccountUser" = ["user:foo@example.com"]
  #   }
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "${var.project_id}" = [
      "roles/container.clusterAdmin",
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}


module "jumpbox" {
  source     = "../modules/compute-vm"
  project_id = var.project_id
  zone       = var.zone
  name       = var.jumpbox_vm_name
  instance_type = "f1-micro"
  network_interfaces = [{
     network    = module.gke_vpc.network.self_link
     subnetwork = module.gke_vpc.subnet_self_links["${var.region}/${var.gke_subnet_name}"]
     addresses ={external=null,internal=""}
  }]
  service_account="${var.jumpbox_sac_name}@${var.project_id}.iam.gserviceaccount.com"
  service_account_scopes = ["cloud-platform"]
}

# K8S Cluster Creation
module "gke-cluster-1" {
  source     = "../modules/gke-cluster"
  project_id = var.project_id
  name       = var.gke_cluster_name
  location   = var.gke_cluster_location
  vpc_config = {
    network    = module.gke_vpc.network.self_link
    subnetwork = module.gke_vpc.subnet_self_links["${var.region}/${var.gke_subnet_name}"]
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
    master_authorized_ranges = {
      internal-vms = "10.0.0.0/8"
    }
    master_ipv4_cidr_block = "192.168.1.0/28"
  }
  max_pods_per_node = 32
  private_cluster_config = {
    enable_private_endpoint = true
    master_global_access    = false
  }
  labels = {
    environment = "dev"
  }
}
# K8S Nodepool creation
module "gke-cluster-1-nodepool-1" {
  source       = "../modules/gke-nodepool"
  project_id   = var.project_id
  cluster_id = module.gke-cluster-1.id
  cluster_name = var.gke_cluster_name
  location     = var.gke_cluster_location
  name         = var.gke_pool1_name
 labels       = { environment = "dev" }
  service_account = {
    create       = true
    email        = "${var.gke_pool1_name}" # optional
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  node_config = {
    machine_type        = var.gke_pool1_type
    disk_size_gb        = var.gke_pool1_disk_size
    disk_type           = var.gke_pool1_disk_type
    ephemeral_ssd_count = 1
    gvnic               = true
    spot                = true
  }
  nodepool_config = {
    autoscaling = {
      max_node_count = var.gke_pool1_max_nodes
      min_node_count = var.gke_pool1_min_nodes
    }
    management = {
      auto_repair  = true
      auto_upgrade = true
    }
  }
}