variable "app_name" {
  type = string
}

provider "kubernetes" {
  load_config_file = false
  host = "https://${data.google_container_cluster.cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(data.google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)}"
  token = "${data.google_client_config.current.access_token}"
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name = "${var.app_name}"
    labels = {
      app = "${var.app_name}"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "${var.app_name}"
      }
    }

    template {
      metadata {
        name = "${var.app_name}"
        labels = {
          app = "${var.app_name}"
        }
      }

      spec {
        container {
          image = "gcr.io/${var.project}/${var.image}"
          name = "${var.app_name}"
        }
      }
    }
  }
}


resource "kubernetes_service" "service" {
  metadata {
    name = "${var.app_name}"
  }

  spec {
    selector = {
      app = "${var.app_name}"
    }
    port {
      port = 80
      target_port = 3000
    }
  }
}
