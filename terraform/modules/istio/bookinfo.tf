resource "kubernetes_namespace" "istio_bookinfo" {
  metadata {
    name = var.istio_bookinfo_namespace

    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "null_resource" "istio_wait" {
  depends_on       = [helm_release.istio]
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "helm_release" "istio_bookinfo" {
  name      = "istio-bookinfo"
  chart     = "${path.root}/charts/istio-bookinfo/"
  namespace = kubernetes_namespace.istio_bookinfo.metadata[0].name

  depends_on = [null_resource.istio_wait]

  set {
    name  = "gateway.hostname"
    value = var.istio_bookinfo_hostname
  }
}
