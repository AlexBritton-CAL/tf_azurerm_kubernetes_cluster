output cluster_name {
  description = "The name of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster."
  value       = try(azurerm_kubernetes_cluster.this.oidc_issuer_url, null)
}