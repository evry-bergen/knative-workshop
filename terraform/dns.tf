resource "google_compute_address" "istio_gateway" {
  name    = "istio-gateway"
  region  = "${var.google_region}"
  project = "${var.google_project}"
}

output "istio_gateway_ip" {
  value = "${google_compute_address.istio_gateway.address}"
}

# DNS knative.site
# resource "google_dns_managed_zone" "knative_site" {
#   name        = "knative-site"
#   dns_name    = "knative.site."
#   description = "knative.site DNS zone"
#   project     = "${var.google_project}"
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }

data "google_dns_managed_zone" "knative_site" {
  name    = "knative-site"
  project = "${var.google_project}"
}

resource "google_dns_record_set" "knative_site_booster" {
  name         = "*.booster.${data.google_dns_managed_zone.knative_site.dns_name}"
  managed_zone = "${data.google_dns_managed_zone.knative_site.name}"
  type         = "A"
  ttl          = 60

  rrdatas = ["${google_compute_address.istio_gateway.address}"]

  project = "${var.google_project}"
}

output "knative_site_ns" {
  value = "${data.google_dns_managed_zone.knative_site.name_servers}"
}

# DNS knative.club
# resource "google_dns_managed_zone" "knative_club" {
#   name        = "knative-club"
#   dns_name    = "knative.club."
#   description = "knative.club DNS zone"
#   project     = "${var.google_project}"
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }

data "google_dns_managed_zone" "knative_club" {
  name    = "knative-club"
  project = "${var.google_project}"
}

output "knative_club_ns" {
  value = "${data.google_dns_managed_zone.knative_club.name_servers}"
}

#resource "google_dns_record_set" "knative_club_presentation" {
#  name         = "${google_dns_managed_zone.knative_club.dns_name}"
#  managed_zone = "${google_dns_managed_zone.knative_club.name}"
#  type         = "A"
#  ttl          = 300
#
#  rrdatas = [
#    "185.199.111.153",
#    "185.199.108.153",
#    "185.199.109.153",
#    "185.199.110.153",
#  ]
#
#  project = "${var.google_project}"
#
#  lifecycle {
#    prevent_destroy = true
#  }
#}

resource "google_dns_record_set" "knative_club_booster" {
  name         = "*.booster.${data.google_dns_managed_zone.knative_club.dns_name}"
  managed_zone = "${data.google_dns_managed_zone.knative_club.name}"
  type         = "A"
  ttl          = 60

  rrdatas = ["${google_compute_address.istio_gateway.address}"]

  project = "${var.google_project}"
}
