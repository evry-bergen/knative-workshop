resource "google_container_node_pool" "nodes" {
  provider = "google-beta"

  name       = "nodes"
  zone       = "${var.zone}"
  cluster    = "${google_container_cluster.cluster.name}"
  node_count = "${var.min_node_count}"

  node_config {
    preemptible  = "${var.node_preemptible}"
    machine_type = "${var.node_machine_type}"
    disk_size_gb = "${var.node_disk_size}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    ]
  }

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }

  management {
    auto_repair  = "${var.auto_repair}"
    auto_upgrade = "${var.auto_upgrade}"
  }
}

resource "google_container_cluster" "cluster" {
  provider = "google-beta"

  name                     = "${var.cluster_name}"
  description              = "Primary Kubernetes Cluseter"
  zone                     = "${var.zone}"
  enable_kubernetes_alpha  = "${var.enable_kubernetes_alpha}"
  enable_legacy_abac       = "${var.enable_legacy_abac}"
  initial_node_count       = "${var.min_node_count}"
  remove_default_node_pool = "true"
  logging_service          = "${var.logging_service}"
  monitoring_service       = "${var.monitoring_service}"

  min_master_version = "${var.cluster_version}"

  ip_allocation_policy = {
    cluster_ipv4_cidr_block = "10.2.0.0/19"
  }

  addons_config {
    istio_config {
      disabled = false
    }

    cloudrun_config {
      disabled = false
    }
  }

  resource_labels {
    created-with = "terraform"
  }

  lifecycle {
    ignore_changes = [
      "node_pool",
      "ip_allocation_policy",
      "network",
      "subnetwork",
    ]
  }
}
