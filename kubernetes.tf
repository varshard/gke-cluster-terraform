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

resource "kubernetes_config_map" "pg_master_config" {
  metadata {
    name = "pg-master-conf"
  }

  data = {
    POSTGRES_USER = "title"
    POSTGRES_PASSWORD = "password"
    POSTGRES_DB = "guessbook"
    PG_REP_USER = "rep"
    PG_REP_PASSWORD = "password"
  }
}

resource "kubernetes_config_map" "pg_slave_config" {
  metadata {
    name = "pg-slave-conf"
  }

  data = {
    POSTGRES_USER = "title"
    POSTGRES_PASSWORD = "password"
    POSTGRES_DB = "guessbook"
    PG_REP_USER = "rep"
    PG_REP_PASSWORD = "password"
    // GCE is using IP-based load balancer
    PG_MASTER_HOST = kubernetes_service.pg_master_svc.load_balancer_ingress[0].ip
    // For AWS, which use hostname-based load balancer
    //PG_MASTER_HOST = kubernetes_service.pg_master_svc.load_balancer_ingress[0].hostname

    PG_MASTER_PORT = "5432"
  }
}

resource "kubernetes_deployment" "pg_master" {
  metadata {
    name = "pg-master"
    labels = {
      app = "pg-master"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "pg-master"
      }
    }
    template {
      metadata {
        name = "pg-master"
        labels = {
          app = "pg-master"
        }
      }
      spec {
        container {
          image = "gcr.io/${var.project}/pg-master:11.5-alpine"
          name = "pg-master"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.pg_master_config.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pg_master_svc" {
  metadata {
    name = "pg-master"
  }

  spec {
    selector = {
      app = "pg-master"
    }
    port {
      port = 5432
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "pg_slave" {
  metadata {
    name = "pg-slave"
    labels = {
      app = "pg-slave"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "pg-slave"
      }
    }
    template {
      metadata {
        name = "pg-slave"
        labels = {
          app = "pg-slave"
        }
      }
      spec {
        container {
          image = "gcr.io/${var.project}/pg-slave:11.5-alpine"
          name = "pg-slave"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.pg_slave_config.metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "pg_slave_svc" {
  metadata {
    name = "pg-slave"
  }

  spec {
    selector = {
      app = "pg-slave"
    }
    port {
      port = 5432
    }

    type = "LoadBalancer"
  }
}
