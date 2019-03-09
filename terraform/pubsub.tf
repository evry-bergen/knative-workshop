resource "google_pubsub_topic" "testing" {
  name    = "testing"
  project = "${var.google_project}"

  labels = {
    "created-with" = "terraform"
    "used-by"      = "knative-lab-3"
  }
}
