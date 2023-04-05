module "vpc" {
  source     = "../modules/net-vpc"
  project_id = var.project_id
  name       = var.network_name
  subnets = [
    {
      ip_cidr_range = "10.50.0.0/16"
      name          = "subnet-cluster"
      region        = var.location
      secondary_ip_ranges = {
        pods     = "172.16.0.0/20"
        services = "192.168.0.0/24"
      }
    }
  ]
}

module "nat" {
  source         = "../modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.location
  name           = var.nat_name
  router_network = module.vpc.network.name
  router_create  = true
  router_name = var.router_name
}


module "myproject-default-service-accounts" {
  source     = "../modules/iam-service-account"
  project_id = var.project_id
  name       = var.sac_name
  # authoritative roles granted *on* the service accounts to other identities
#   iam = {
#     "roles/iam.serviceAccountUser" = ["user:foo@example.com"]
#   }
  # non-authoritative roles granted *to* the service accounts on other resources
#   iam_project_roles = {
#     "myproject" = [
#       "roles/logging.logWriter",
#       "roles/monitoring.metricWriter",
#     ]
#   }
}


module "simple-vm-example" {
  source     = "../modules/compute-vm"
  project_id = var.project_id
  zone       = var.zone
  name       = var.jumpbox_name
  instance_type = "f1-micro"
  network_interfaces = [{
     network    = module.vpc.network.self_link
     subnetwork = module.vpc.subnet_self_links["${var.location}/subnet-cluster"]
     addresses ={external=null,internal=""}
  }]
  service_account="${var.sac_name}@${var.project_id}.iam.gserviceaccount.com"
  service_account_scopes = ["cloud-platform"]
}




# # K8S Cluster Creation
# module "cluster-1" {
#   source     = "../modules/gke-cluster"
#   project_id = var.project_id
#   name       = var.gke_name
#   location   = var.zone
#   vpc_config = {
#     network    = module.vpc.network.self_link
#     subnetwork = module.vpc.subnet_self_links["${var.location}/subnet-cluster"]
#     secondary_range_names = {
#       pods     = "pods"
#       services = "services"
#     }
#     master_authorized_ranges = {
#       internal-vms = "10.0.0.0/8"
#     }
#     master_ipv4_cidr_block = "192.168.1.0/28"
#   }
#   max_pods_per_node = 32
#   private_cluster_config = {
#     enable_private_endpoint = true
#     master_global_access    = false
#   }
#   labels = {
#     environment = "dev"
#   }
# }
# # K8S Nodepool creation
# module "cluster-1-nodepool-1" {
#   source       = "../modules/gke-nodepool"
#   project_id   = var.project_id
#   cluster_id = module.cluster-1.id
#   cluster_name = var.gke_name
#   location     = var.zone
#   name         = "nodepool-1"
#  labels       = { environment = "dev" }
#   service_account = {
#     create       = true
#     email        = "nodepool-1" # optional
#     oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
#   }
#   node_config = {
#     machine_type        = "n2-standard-2"
#     disk_size_gb        = 50
#     disk_type           = "pd-ssd"
#     ephemeral_ssd_count = 1
#     gvnic               = true
#     spot                = true
#   }
#   nodepool_config = {
#     autoscaling = {
#       max_node_count = 10
#       min_node_count = 1
#     }
#     management = {
#       auto_repair  = true
#       auto_upgrade = true
#     }
#   }
# }