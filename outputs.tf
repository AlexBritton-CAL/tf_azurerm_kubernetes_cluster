output "kubernetes_cluster_id" {
  description = "The ID of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "kubernetes_cluster_name" {
  description = "The name of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kubernetes_cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the cluster."
  value       = try(azurerm_kubernetes_cluster.this.oidc_issuer_url, null)
}

output "kubernetes_cluster_defaults" {
  value = local.kube_defaults
}

output "kubernetes_cluster_cluster_identity" {
  description = "The cluster control plane managed identity."
  value = {
    principal_id = azurerm_user_assigned_identity.cluster_identity.principal_id
    client_id    = azurerm_user_assigned_identity.cluster_identity.client_id
  }
}

output "kubernetes_cluster_kubelet_identity" {
  description = "The kubelet managed identity."
  value = {
    principal_id = azurerm_user_assigned_identity.kubelet_identity.principal_id
    client_id    = azurerm_user_assigned_identity.kubelet_identity.client_id
  }
}

output "kubernetes_cluster_certmanager_identity" {
  description = "The cert-manager managed identity."
  value = {
    principal_id = azurerm_user_assigned_identity.certmanager.principal_id
    client_id    = azurerm_user_assigned_identity.certmanager.client_id
  }
}

output "kubernetes_cluster_keyvault_identity" {
  description = "The Istio ingress gateway Key Vault managed identity."
  value = {
    principal_id = azurerm_user_assigned_identity.keyvault.principal_id
    client_id    = azurerm_user_assigned_identity.keyvault.client_id
  }
}

output "kubernetes_cluster_crossplane_identity" {
  description = "The Crossplane managed identity."
  value = {
    principal_id = azurerm_user_assigned_identity.crossplane.principal_id
    client_id    = azurerm_user_assigned_identity.crossplane.client_id
  }
}
