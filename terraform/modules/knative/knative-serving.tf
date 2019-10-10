resource "kubernetes_namespace" "knative_serving" {
  metadata {
    name = var.knative_serving_namespace

    labels = {
      "istio-injection" = "enabled"
      "serving.knative.dev/release" = "v0.9.0"
    }
  }
}

resource "helm_release" "knative_serving" {
  name      = "knative-serving"
  chart     = "${path.root}/charts/knative-serving/"
  namespace = kubernetes_namespace.knative_serving.metadata[0].name

  set {
    name  = "route.domains[0].domain"
    value = var.knative_serving_domain
  }

  set {
    name  = "route.domainTemplate"
    value = "\\{\\{.Name\\}\\}-\\{\\{.Namespace\\}\\}.\\{\\{.Domain\\}\\}"
  }
}
