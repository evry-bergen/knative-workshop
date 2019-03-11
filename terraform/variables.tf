variable "helm_version" {
  default = "v2.11.0"
}

variable "google_project" {}
variable "google_region" {}
variable "google_zone" {}

variable "k8s_cluster_name" {}
variable "k8s_cluster_version" {}
variable "k8s_node_machine_type" {}
variable "k8s_min_node_count" {}
variable "k8s_max_node_count" {}
