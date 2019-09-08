
data "google_container_cluster" "cluster" {
  name     = "${var.project}-cluster"
  location = "${var.region}"
}

resource "google_container_cluster" "cluster" {
  name     = "${data.google_container_cluster.cluster.name}"
  location = "${data.google_container_cluster.cluster.location}"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  addons_config {
    network_policy_config {
      disabled = "false"
    }
  }

  network_policy {
    enabled = "true"
    provider = "CALICO"
  }
}

resource "google_container_node_pool" "general_purpose" {
  name       = "${var.project}-general"
  location   = "${var.region}"
  cluster    = "${google_container_cluster.cluster.name}"

  management {
    auto_repair = "true"
    auto_upgrade = "true"
  }

  autoscaling {
    min_node_count = "${var.general_purpose_min_node_count}"
    max_node_count = "${var.general_purpose_max_node_count}"
  }
  initial_node_count = "${var.general_purpose_min_node_count}"

  node_config {
    machine_type = "${var.general_purpose_machine_type}"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Needed for correctly functioning cluster, see
    # https://www.terraform.io/docs/providers/google/r/container_cluster.html#oauth_scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
}
