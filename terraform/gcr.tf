resource "google_service_account" "knative_build_sa" {
  account_id   = "knative-build"
  display_name = "Knative Build Service Account"
  project      = "${var.google_project}"
}

resource "google_project_iam_member" "knative_build_sa" {
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.knative_build_sa.account_id}@${var.google_project}.iam.gserviceaccount.com"
  project = "${var.google_project}"
}

resource "google_service_account_key" "knative_build_sa" {
  service_account_id = "${google_service_account.knative_build_sa.name}"
}

output "knative_build_sa_id" {
  value     = "${google_service_account.knative_build_sa.account_id}@${var.google_project}.iam.gserviceaccount.com"
  sensitive = true
}

output "knative_build_sa_key" {
  value     = "${google_service_account_key.knative_build_sa.private_key}"
  sensitive = true
}

resource "kubernetes_secret" "knative_registry_creds" {
  metadata {
    name      = "gcr-auth"
    namespace = "default"

    annotations {
      "build.knative.dev/docker-0" = "https://eu.gcr.io"
    }
  }

  data {
    username = "_json_key"
    password = "${base64decode("${google_service_account_key.knative_build_sa.private_key}")}"
  }

  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_service_account" "knative_build_bot" {
  metadata {
    name      = "build-bot"
    namespace = "default"
  }

  secret {
    name = "${kubernetes_secret.knative_registry_creds.metadata.0.name}"
  }
}
