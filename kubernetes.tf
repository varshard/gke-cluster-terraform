variable "ping" {
  type = string
  default = "gin-3000"
}

variable "pong" {
  type = string
  default = "gin-3001"
}

module "gke" {
  source = "./modules/gke"

  project = var.project
  region = var.region
  credentials = file(var.gce_credential_path)
  general_purpose_min_node_count = var.general_purpose_min_node_count
  general_purpose_max_node_count = var.general_purpose_max_node_count
  general_purpose_machine_type = var.general_purpose_machine_type
}

provider "kubernetes" {
  load_config_file = false
  host = "https://${module.gke.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  token = module.gke.access_token
}

resource "kubernetes_deployment" "ping" {
  metadata {
    name = var.ping
    labels = {
      app = var.ping
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        app = var.ping
      }
    }
    template {
      metadata {
        name = var.ping
        labels = {
          app = var.ping
        }
      }
      spec {
        container {
          image = "gcr.io/${var.project}/golang-gin:v2-3000"
          name = var.ping
        }
      }
    }
  }
}

resource "kubernetes_service" "ping_service" {
  metadata {
    name = var.ping
  }

  spec {
    selector = {
      app = var.ping
    }
    port {
      port = 3000
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "pong" {
  metadata {
    name = var.pong
    labels = {
      app = var.pong
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        app = var.pong
      }
    }
    template {
      metadata {
        name = var.pong
        labels = {
          app = var.pong
        }
      }
      spec {
        container {
          image = "gcr.io/${var.project}/golang-gin:v2-3001"
          name = var.pong
        }
      }
    }
  }
}

resource "kubernetes_service" "pong_service" {
  metadata {
    name = "pingpong-3001"
  }

  spec {
    selector = {
      app = var.pong
    }
    port {
      port = 3001
    }

    type = "LoadBalancer"
  }
}

