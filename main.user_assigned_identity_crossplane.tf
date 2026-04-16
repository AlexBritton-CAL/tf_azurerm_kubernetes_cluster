locals {
  crossplane-ns      = "crossplane-system"
  crossplane-sa_name = "crossplane-workload-id-sa"
}

resource "azurerm_user_assigned_identity" "crossplane" {
  location            = local.location
  name                = coalesce(try(var.config.identity.crossplane_identity.name, null), local.module_defaults.identity.crossplane_identity.name)
  resource_group_name = var.resource_group_name
}

resource "azurerm_federated_identity_credential" "crossplane" {
  name       = "${azurerm_kubernetes_cluster.this.name}-ServiceAccount-${local.crossplane-ns}-${local.crossplane-sa_name}"
  audience   = ["api://AzureADTokenExchange"]
  issuer     = azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id  = azurerm_user_assigned_identity.crossplane.id
  subject    = "system:serviceaccount:${local.crossplane-ns}:${local.crossplane-sa_name}"
}
