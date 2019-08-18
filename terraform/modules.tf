module "gke" {
  source = "./modules/gke"

  // Google Cloud Platform config
  project = "${var.google_project}"
  region  = "${var.google_region}"
  zone    = "${var.google_zone}"

  // Google Kubernetes Engine config
  cluster_name      = "${var.k8s_cluster_name}"
  cluster_version   = "${var.k8s_cluster_version}"
  node_machine_type = "${var.k8s_node_machine_type}"
  min_node_count    = "${var.k8s_min_node_count}"
  max_node_count    = "${var.k8s_max_node_count}"
}

module "k8s" {
  source = "./modules/k8s"

  // Google Cloud Platform config
  project = "${var.google_project}"
  region  = "${var.google_region}"
  zone    = "${var.google_zone}"
}

module "istio" {
  source = "./modules/istio"

  operator_version   = "0.0.17"
  operator_namespace = "istio-system"
  istio_version = "1.2.4"
  istio_namespace = "istio-system"
}
