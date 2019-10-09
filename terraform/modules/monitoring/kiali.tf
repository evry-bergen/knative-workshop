resource "helm_release" "kiali" {
  name      = "kiali"
  chart     = "${path.root}/charts/kiali/"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name

  set {
    name  = "tag"
    value = "v1.4.0"
  }

  set {
    name  = "dashboard.auth.strategy"
    value = "anonymous"
  }

  set {
    name  = "prometheusAddr"
    value = "http://prometheus-operator-prometheus:9090"
  }

  set {
    name  = "isitioNmespace"
    value = "istio-system"
  }
}
