module "gke" {
  source = "./modules/gke"

  // Google Cloud Platform config
  project = var.google_project
  region  = var.google_region
  zone    = var.google_zone

  // Google Kubernetes Engine config
  cluster_name      = var.k8s_cluster_name
  cluster_version   = var.k8s_cluster_version
  node_machine_type = var.k8s_node_machine_type
  min_node_count    = var.k8s_min_node_count
  max_node_count    = var.k8s_max_node_count
}

module "k8s" {
  source = "./modules/k8s"

  // Google Cloud Platform config
  project = var.google_project
  region  = var.google_region
  zone    = var.google_zone
}

module "istio" {
  source = "./modules/istio"

  // Hack to make sure the nodepool is ready before deploying
  gke_nodepool = module.gke.nodepool

  operator_namespace = var.istio_operator_namespace
  operator_version   = var.istio_operator_version

  istio_version    = var.istio_version
  istio_gateway_ip = google_compute_address.istio_gateway.address

  istio_bookinfo_namespace = var.istio_bookinfo_namespace
  istio_bookinfo_hostname  = "bookinfo.workshop.knative.site"
}

module "monitoring" {
  source = "./modules/monitoring"

  // Hack to make sure the nodepool is ready before deploying
  gke_nodepool = module.gke.nodepool

  operator_version   = var.prometheus_operator_version
  operator_namespace = var.prometheus_operator_namespace
}

module "knative" {
  source = "./modules/knative"

  // Hack to make sure knative is deployed after istio
  istio_wait_id = module.istio.istio_wait_id

  knative_serving_namespace = "knative-serving"
  knative_serving_domain    = "workshop.knative.site"
}
