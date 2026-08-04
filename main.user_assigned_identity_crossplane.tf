locals {
  crossplane-ns      = "crossplane-system"
  crossplane-sa_name = "crossplane-workload-id-sa"
  crossplane-enabled = try(var.config.identity.crossplane_identity.enabled, false)
}

resource "azurerm_user_assigned_identity" "crossplane" {
  count               = local.crossplane-enabled ? 1 : 0
  location            = local.location
  name                = coalesce(try(var.config.identity.crossplane_identity.name, null), local.module_defaults.identity.crossplane_identity.name)
  resource_group_name = var.resource_group_name
}

resource "azurerm_federated_identity_credential" "crossplane" {
  count              = local.crossplane-enabled ? 1 : 0
  name               = "${azurerm_kubernetes_cluster.this.name}-ServiceAccount-${local.crossplane-ns}-${local.crossplane-sa_name}"
  audience           = ["api://AzureADTokenExchange"]
  issuer             = azurerm_kubernetes_cluster.this.oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.crossplane[count.index].id
  subject            = "system:serviceaccount:${local.crossplane-ns}:${local.crossplane-sa_name}"
}

resource "azurerm_role_assignment" "crossplane_subscrption_contributor" {
  count = local.crossplane-enabled ? 1 : 0
  principal_id                     = azurerm_user_assigned_identity.crossplane[0].principal_id
  role_definition_name             = "Custom Role - Domain Runner"
  scope                            = "/subscriptions/${var.global_config.global.subscription_id}"
  skip_service_principal_aad_check = true
}
