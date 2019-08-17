provider "google-beta" {
  project = "${var.google_project}"
  region  = "${var.google_region}"
  zone    = "${var.google_zone}"
}

data "google_client_config" "current" {}

provider "kubernetes" {
  host = "${module.gke.host}"

  cluster_ca_certificate = "${base64decode(module.gke.cluster_ca_certificate)}"
  token                  = "${data.google_client_config.current.access_token}"
  load_config_file       = false
}

provider "helm" {
  tiller_image = "gcr.io/kubernetes-helm/tiller:${var.helm_version}"

  service_account = "tiller"

  kubernetes {
    host = "${module.gke.host}"

    cluster_ca_certificate = "${base64decode(module.gke.cluster_ca_certificate)}"
    token                  = "${data.google_client_config.current.access_token}"
    load_config_file       = false
  }
}
