resource "kubernetes_service_account" "tiller_service_account" {
  metadata {
    name = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller_cluster_role_binding" {
  metadata {
    name = "tiller"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tiller_service_account.metadata.0.name
    namespace = "kube-system"
  }
}

provider "helm" {
  install_tiller = "true"
  service_account = kubernetes_service_account.tiller_service_account.metadata.0.name
  kubernetes {
    host = "https://${module.gke.cluster_endpoint}"
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
    token = module.gke.access_token

    config_context = kubernetes_service_account.tiller_service_account.metadata.0.name
  }
}

data "helm_repository" "stable" {
    name = "stable"
    url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "example" {
  name       = "my-redis-release"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  chart      = "redis"
  version    = "6.0.1"

  values = [
    file("redis.yaml")
  ]

  set {
    name  = "cluster.enabled"
    value = "true"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }
}
