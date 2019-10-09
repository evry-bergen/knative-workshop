resource "kubernetes_namespace" "knative-build" {
  metadata {
    name = "knative-build"
  }
}

resource "kubernetes_namespace" "knative-eventing" {
  metadata {
    name = "knative-eventing"

    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_namespace" "knative-serving" {
  metadata {
    name = "knative-serving"

    labels = {
      "istio-injection"             = "enabled"
      "serving.knative.dev/release" = "devel"
    }
  }
}

resource "kubernetes_namespace" "knative-sources" {
  metadata {
    name = "knative-sources"
  }
}
