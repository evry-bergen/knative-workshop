resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = var.operator_namespace

    labels = {
      "istio-injection" = "disabled"
    }
  }
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

# https://github.com/coreos/prometheus-operator/issues/2502
resource "helm_release" "prometheus-operator" {
  name       = "prometheus-operator"
  namespace  = kubernetes_namespace.prometheus.metadata[0].name
  repository = data.helm_repository.stable.metadata[0].name
  chart      = "stable/prometheus-operator"
  version    = var.operator_version

  values = [
    <<EOF
global:
  rbac:
    enabled: true

commonLabels:
  prometheus: default

defaultRules:
  labels:
    alertmanager: default
  rules:
    alertmanager: true
    etcd: false
    general: true
    k8s: true
    kubeApiserver: false
    kubePrometheusNodeAlerting: true
    kubePrometheusNodeRecording: true
    kubeScheduler: false
    kubernetesAbsent: false
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    node: true
    prometheusOperator: true
    prometheus: true

alertmanager:
  enabled: false

prometheus:
  additionalServiceMonitors:
    - name: istio
      selector: {}
      matchExpressions:
        - {key: istio, operator: In, values: [pilot, mixer]}
      namespaceSelector:
        matchNames:
          - istio-system
      jobLabel: istio
      endpoints:
      - port: prometheus
        interval: 5s
      - port: http-monitoring
        interval: 5s
      - port: statsd-prom
        interval: 5s
  prometheusSpec:
    secrets:
      - istio.default
      - istio.prometheus-operator-prometheus
    ruleNamespaceSelector: {}
    serviceMonitorSelector:
      matchLabels:
        prometheus: default
    ruleSelector:
      matchLabels:
        alertmanager: default
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

    additionalScrapeConfigs:
      - job_name: envoy-stats
        scrape_interval: 15s
        scrape_timeout: 10s
        metrics_path: /stats/prometheus
        scheme: http
        kubernetes_sd_configs:
        - api_server: null
          role: pod
          namespaces:
            names: []
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_container_port_name]
          separator: ;
          regex: .*-envoy-prom
          replacement: $1
          action: keep
        - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
          separator: ;
          regex: ([^:]+)(?::\d+)?;(\d+)
          target_label: __address__
          replacement: $1:15090
          action: replace
        - separator: ;
          regex: __meta_kubernetes_pod_label_(.+)
          replacement: $1
          action: labelmap
        - source_labels: [__meta_kubernetes_namespace]
          separator: ;
          regex: (.*)
          target_label: namespace
          replacement: $1
          action: replace
        - source_labels: [__meta_kubernetes_pod_name]
          separator: ;
          regex: (.*)
          target_label: pod_name
          replacement: $1
          action: replace
        metric_relabel_configs:
        - source_labels: [cluster_name]
          separator: ;
          regex: (outbound|inbound|prometheus_stats).*
          replacement: $1
          action: drop
        - source_labels: [tcp_prefix]
          separator: ;
          regex: (outbound|inbound|prometheus_stats).*
          replacement: $1
          action: drop
        - source_labels: [listener_address]
          separator: ;
          regex: (.+)
          replacement: $1
          action: drop
        - source_labels: [http_conn_manager_listener_prefix]
          separator: ;
          regex: (.+)
          replacement: $1
          action: drop
        - source_labels: [http_conn_manager_prefix]
          separator: ;
          regex: (.+)
          replacement: $1
          action: drop
        - source_labels: [__name__]
          separator: ;
          regex: envoy_tls.*
          replacement: $1
          action: drop
        - source_labels: [__name__]
          separator: ;
          regex: envoy_tcp_downstream.*
          replacement: $1
          action: drop
        - source_labels: [__name__]
          separator: ;
          regex: envoy_http_(stats|admin).*
          replacement: $1
          action: drop
        - source_labels: [__name__]
          separator: ;
          regex: envoy_cluster_(lb|retry|bind|internal|max|original).*
          replacement: $1
          action: drop
      #- job_name: 'istio-mesh'
      #  scrape_interval: 5s
      #  kubernetes_sd_configs:
      #  - role: endpoints
      #    namespaces:
      #      names:
      #      - istio-system
      #  relabel_configs:
      #  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      #    action: keep
      #    regex: istio-telemetry;prometheus
      #- job_name: 'istio-policy'
      #  scrape_interval: 5s
      #  kubernetes_sd_configs:
      #  - role: endpoints
      #    namespaces:
      #      names:
      #      - istio-system
      #  relabel_configs:
      #  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      #    action: keep
      #    regex: istio-policy;http-monitoring
      #- job_name: 'istio-telemetry'
      #  scrape_interval: 5s
      #  kubernetes_sd_configs:
      #  - role: endpoints
      #    namespaces:
      #      names:
      #      - istio-system
      #  relabel_configs:
      #  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      #    action: keep
      #    regex: istio-telemetry;http-monitoring
      #- job_name: 'pilot'
      #  scrape_interval: 5s
      #  kubernetes_sd_configs:
      #  - role: endpoints
      #    namespaces:
      #      names:
      #      - istio-system
      #  relabel_configs:
      #  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      #    action: keep
      #    regex: istio-pilot;http-monitoring
      #- job_name: 'galley'
      #  scrape_interval: 5s
      #  kubernetes_sd_configs:
      #  - role: endpoints
      #    namespaces:
      #      names:
      #      - istio-system
      #  relabel_configs:
      #  - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      #    action: keep
      #    regex: istio-galley;http-monitoring

grafana:
  enabled: true

  rbac:
    create: true

  adminUser: admin
  adminPassword: admin

  persistence:
    enabled: true
    storageClassName: standard
    accessModes:
    - ReadWriteOnce
    size: 8Gi

  env:
    GF_AUTH_ANONYMOUS_ENABLED: true
    GF_AUTH_ANONYMOUS_ORG_NAME: Main Org.
    GF_AUTH_ANONYMOUS_ORG_ROLE: Editor

  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      searchNamespace: ALL

coreDns:
  enabled: false
kubeDns:
  enabled: true
kubeScheduler:
  enabled: false
kubeApi:
  enabled: false
kubeControllerManager:
  enabled: false
kubeEtcd:
  enabled: false
EOF
  ]
}

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-istio-dashboards"
    namespace = kubernetes_namespace.prometheus.metadata[0].name

    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "galley-dashboard.json"            = file("${path.root}/config/grafana/dashboards/galley-dashboard.json")
    "istio-mesh-dashboard.json"        = file("${path.root}/config/grafana/dashboards/istio-mesh-dashboard.json")
    "istio-performance-dashboard.json" = file("${path.root}/config/grafana/dashboards/istio-performance-dashboard.json")
    "istio-service-dashboard.json"     = file("${path.root}/config/grafana/dashboards/istio-service-dashboard.json")
    "istio-workload-dashboard.json"    = file("${path.root}/config/grafana/dashboards/istio-workload-dashboard.json")
    "mixer-dashboard.json"             = file("${path.root}/config/grafana/dashboards/mixer-dashboard.json")
    "pilot-dashboard.json"             = file("${path.root}/config/grafana/dashboards/pilot-dashboard.json")
  }
}
