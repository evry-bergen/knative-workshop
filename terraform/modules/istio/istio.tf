resource "helm_release" "istio" {
  name       = "istio"
  chart     = "${path.root}/charts/istio-gke/"
  namespace  = "${var.istio_namespace}"

  depends_on = ["helm_release.istio_operator"]

  set {
    name  = "istio.version"
    value = "${var.istio_version}"
  }
}
