variable "project" {
  description = "GCP project name"
}

variable "region" {
  description = "GCP region"
}

variable "zone" {
  description = "GCP zone"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
}

variable "min_node_count" {
  description = "Min Number of worker VMs to create"
  default     = 2
}

variable "max_node_count" {
  description = "Max Number of worker VMs to create"
  default     = 5
}

variable "node_machine_type" {
  description = "GCE machine type"
  default     = "n1-standard-4"
}

variable "node_preemptible" {
  description = "Use preemptible nodes"
  default     = "false"
}

variable "node_disk_size" {
  description = "Node disk size in GB"
  default     = "20"
}

variable "enable_kubernetes_alpha" {
  default = "false"
}

variable "enable_legacy_abac" {
  default = "true"
}

variable "auto_repair" {
  default = "true"
}

variable "auto_upgrade" {
  default = "true"
}

variable "monitoring_service" {
  description = "The monitoring service to use. Can be monitoring.googleapis.com, monitoring.googleapis.com/kubernetes (beta) and none"
  default     = "monitoring.googleapis.com"
}

variable "logging_service" {
  description = "The logging service to use. Can be logging.googleapis.com, logging.googleapis.com/kubernetes (beta) and none"
  default     = "logging.googleapis.com"
}
