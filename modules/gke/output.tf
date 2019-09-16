output "cluster_endpoint" {
  value = google_container_cluster.cluster.endpoint
}

output "cluster_ca_certificate" {
  value = google_container_cluster.cluster.master_auth.0.cluster_ca_certificate
}

output "access_token" {
  value = data.google_client_config.current.access_token
}
