variable "project_id" {
    type = string
}
variable "zone"{
    type = string
}
variable "region" {
    type = string
}
variable "gke_network_name" {
        type = string
}
variable "gke_subnet_name" {
    type = string
}
variable "gke_cidr_range" {
    type = string
}
variable "gke_pods_range" {
    type = string
}
variable "gke_services_range" {
    type = string
}

variable "gke_nat_name" {
    type = string
}
variable "gke_router_name" {
    type = string
}

variable "jumpbox_sac_name" {
    type=string
}
variable "jumpbox_vm_name"{
    type = string
}




variable "gke_cluster_name" {
    type = string
}
variable "gke_cluster_location" {
        type = string
}
variable "gke_pool1_name"{
    type=string
}


variable "gke_pool1_type" {
    type = string
}
variable "gke_pool1_disk_size" {
    type = number
}
variable "gke_pool1_disk_type" {
    type = string
}
variable "gke_pool1_max_nodes" {
    type = number
}
variable "gke_pool1_min_nodes" {
    type = number
}




