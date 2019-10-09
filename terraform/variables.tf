variable "helm_version" {
  default = "v2.14.3"
}

variable "google_project" {
  default = "knative-workshop-2019"
}

variable "google_region" {
  default = "europe-north1"
}

variable "google_zone" {
  default = "europe-north1-a"
}

variable "k8s_cluster_name" {
  default = "knative-workshop"
}

variable "k8s_cluster_version" {
  default = "1.13.7-gke.24"
}

variable "k8s_node_machine_type" {
  default = "n1-standard-4"
}

variable "k8s_min_node_count" {
  default = 1
}

variable "k8s_max_node_count" {
  default = 5
}

variable "istio_operator_version" {
  default = "0.0.20"
}

variable "istio_operator_namespace" {
  default = "istio-system"
}

variable "istio_version" {
  default = "1.3.0"
}

variable "istio_bookinfo_namespace" {
  default = "bookinfo"
}

variable "prometheus_operator_version" {
  default = "6.14.0"
}

variable "prometheus_operator_namespace" {
  default = "monitoring"
}
