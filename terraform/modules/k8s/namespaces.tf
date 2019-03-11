resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"

    labels {
      "istio-injection" = "disabled"
    }
  }
}

resource "kubernetes_namespace" "knative-build" {
  metadata {
    name = "knative-build"
  }
}

resource "kubernetes_namespace" "knative-eventing" {
  metadata {
    name = "knative-eventing"

    labels {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_namespace" "knative-serving" {
  metadata {
    name = "knative-serving"

    labels {
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

resource "kubernetes_namespace" "knative-monitoring" {
  metadata {
    name = "knative-monitoring"

    labels {
      "serving.knative.dev/release" = "devel"
    }
  }
}
