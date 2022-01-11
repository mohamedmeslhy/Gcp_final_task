provider "google" {
  project = "active-sun-337308"
  region  = "us-west1"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.66"
    }
  }
}


# Main VPC
# https://www.terraform.io/docs/providers/google/r/compute_network.html#example-usage-network-basic
resource "google_compute_network" "main" {
  name                    = "main"
  auto_create_subnetworks = false
}

# Public Subnet
# https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "public" {
  name          = "public"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-west1"
  network       = google_compute_network.main.id
}

# Private Subnet
# https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "private" {
  name          = "private"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.main.id
}

# Cloud Router
# https://www.terraform.io/docs/providers/google/r/compute_router.html
resource "google_compute_router" "router" {
  name    = "router"
  region  = google_compute_subnetwork.public.region
  network = google_compute_network.main.id
  bgp {
    asn            = 64514
    advertise_mode = "CUSTOM"
  }
}
# NAT Gateway
# https://www.terraform.io/docs/providers/google/r/compute_router_nat.html
resource "google_compute_router_nat" "nat" {
  name                               = "nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = "public"
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
# fire wall
##########################################################################
resource "google_compute_firewall" "rules" {

  project    = "active-sun-337308"
  name       = "allow1"
  network    = google_compute_network.main.id
  allow {
    protocol = "tcp"
    ports = ["80", "22", "443"]

  }
  source_ranges = ["35.235.240.0/20"]
}

# VM private in public subnet
#########################################################################

resource "google_compute_instance" "vm" {
  name         = "vm"
  machine_type = "f1-micro"
  zone         = "us-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  // Make sure flask is installed on all new instances for later steps
  metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync; pip install flask"

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.public.id

  }
}

#service account

resource "google_service_account" "service_account" {
  account_id   = "service-acount-moselhy"
  display_name = "service-acount-for-moselhy-project"
}

resource "google_project_iam_binding" "service_account" {
  project = "active-sun-337308"
  role    = "roles/container.admin"
  depends_on = [
    google_service_account.service_account
  ]
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

#######################################################################

resource "google_container_cluster" "primary" {
  name                     = "my-gke-cluster"
  location                 = "us-west1"
  network                  = google_compute_network.main.id
  subnetwork               = google_compute_subnetwork.private.id
  remove_default_node_pool = true
  initial_node_count       = 1

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "10.0.0.0/24"
    }
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes = true
    master_ipv4_cidr_block = "172.16.0.0/28"
    master_global_access_config {
      enabled = false
    }
  }

  ip_allocation_policy {

    cluster_ipv4_cidr_block = "10.4.0.0/16"
    services_ipv4_cidr_block = "10.5.0.0/16"
  } 

}

######################################################################
resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "us-west1"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "e2-medium"
    service_account = google_service_account.service_account.email
    
  }
}
