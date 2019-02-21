module "gke" {
  source = "./modules/gke"

  // Google Cloud Platform config
  project = "${var.google_project}"
  region  = "${var.google_region}"
  zone    = "${var.google_zone}"

  // Google Kubernetes Engine config
  cluster_name    = "${var.k8s_cluster_name}"
  cluster_version = "${var.k8s_cluster_version}"
  min_node_count  = "${var.k8s_min_node_count}"
  max_node_count  = "${var.k8s_max_node_count}"
}
