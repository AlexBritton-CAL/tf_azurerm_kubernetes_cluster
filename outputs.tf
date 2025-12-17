output "oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster."
  value       = try(azurerm_kubernetes_cluster.this.oidc_issuer_url, null)
}