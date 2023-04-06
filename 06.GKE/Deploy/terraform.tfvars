project_id="mygkeproject-381022"
zone="us-central1-c"
region="us-central1"

gke_network_name="dev-network"
gke_subnet_name="cluster-subnet"
gke_cidr_range="10.50.0.0/16"
gke_pods_range="172.16.0.0/20"
gke_services_range="192.168.0.0/24"

gke_nat_name="kube-nat"
gke_router_name="kube-router"


jumpbox_sac_name="jumpbox-sac"
jumpbox_vm_name = "jumpbox"


gke_cluster_name="cluster-dev"
gke_cluster_location="us-central1"
gke_pool1_name="nodepool-1"
gke_pool1_type="n2-standard-2"
gke_pool1_disk_size=50
gke_pool1_disk_type="pd-ssd"
gke_pool1_max_nodes=10
gke_pool1_min_nodes=1





