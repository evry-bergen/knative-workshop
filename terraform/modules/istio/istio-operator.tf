resource "kubernetes_namespace" "istio" {
  metadata {
    name = var.operator_namespace

    labels = {
      "istio-injection" = "disabled"
    }
  }
}

data "helm_repository" "banzaicloud" {
  name = "banzaicloud-stable"
  url  = "https://kubernetes-charts.banzaicloud.com"
}

resource "helm_release" "istio_operator" {
  name       = "istio-operator"
  namespace  = kubernetes_namespace.istio.metadata[0].name
  repository = data.helm_repository.banzaicloud.metadata[0].name
  chart      = "istio-operator"
  version    = var.operator_version
}
