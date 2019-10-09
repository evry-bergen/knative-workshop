# https://github.com/istio/istio/issues/16189
resource "helm_release" "istio" {
  name      = "istio"
  chart     = "${path.root}/charts/istio-gke/"
  namespace = kubernetes_namespace.istio.metadata[0].name

  depends_on = [helm_release.istio_operator]

  set {
    name  = "istio.version"
    value = var.istio_version
  }

  set {
    name  = "istio.mtls"
    value = "true"
  }

  set {
    name  = "istio.sidecarInjector.rewriteAppHTTPProbe"
    value = "true"
  }

  set {
    name  = "istio.gateways.ingress.loadBalancerIP"
    value = var.istio_gateway_ip
  }
}
