provider "google-beta" {
  project = "${var.google_project}"
  region  = "${var.google_region}"
  zone    = "${var.google_zone}"
}

provider "kubernetes" {
  host = "${module.gke.host}"

  #username = "${var.cluster_username}"
  #password = "${var.cluster_password}"

  client_certificate     = "${base64decode(module.gke.client_certificate)}"
  client_key             = "${base64decode(module.gke.client_key)}"
  cluster_ca_certificate = "${base64decode(module.gke.cluster_ca_certificate)}"
}

#provider "helm" {
#  tiller_image = "gcr.io/kubernetes-helm/tiller:${var.helm_version}"
#
#  # This is not working correctly and needs to be patched manually:
#  # kubectl -n kube-system patch deployment tiller-deploy -p '{"spec": {"template": {"spec": {"automountServiceAccountToken": true}}}}'
#  # https://github.com/terraform-providers/terraform-provider-helm/pull/143
#  service_account = "tiller"
#
#  kubernetes {
#    host = "${module.gke.host}"
#
#    client_certificate     = "${base64decode(module.gke.client_certificate)}"
#    client_key             = "${base64decode(module.gke.client_key)}"
#    cluster_ca_certificate = "${base64decode(module.gke.cluster_ca_certificate)}"
#  }
#}

