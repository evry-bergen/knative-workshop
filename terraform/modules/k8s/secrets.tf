resource "google_service_account" "pubsub_sa" {
  account_id   = "pubsub-sa"
  display_name = "Knative PubSub Service Account"
  project      = "${var.project}"
}

resource "google_project_iam_member" "pubsub_sa" {
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.pubsub_sa.account_id}@${var.project}.iam.gserviceaccount.com"
  project = "${var.project}"
}

resource "google_service_account_key" "pubsub_sa" {
  service_account_id = "${google_service_account.pubsub_sa.name}"
}

resource "kubernetes_secret" "pubsub_sa_knative_sources" {
  metadata {
    name      = "gcppubsub-source-key"
    namespace = "knative-sources"
  }

  data {
    "key.json" = "${base64decode("${google_service_account_key.pubsub_sa.private_key}")}"
  }

  type = "kubernetes.io/generic"
}

resource "kubernetes_secret" "pubsub_sa_default" {
  metadata {
    name      = "gcp-pubsub-key"
    namespace = "default"
  }

  data {
    "key.json" = "${base64decode("${google_service_account_key.pubsub_sa.private_key}")}"
  }

  type = "kubernetes.io/generic"
}
