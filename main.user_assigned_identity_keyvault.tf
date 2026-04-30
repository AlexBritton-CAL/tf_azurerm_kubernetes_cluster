resource "azurerm_user_assigned_identity" "keyvault" {
  location            = local.location
  name                = coalesce(try(var.config.identity.keyvault_identity.name, null), local.module_defaults.identity.keyvault_identity.name)
  resource_group_name = var.resource_group_name
}

locals {
  keyvault-ns      = "aks-istio-ingress"
  keyvault-sa_name = "istio-gateway-certs"
}

resource "azurerm_federated_identity_credential" "keyvault" {
  count               = local.service_mesh_profile.enabled == "false" ? 0 : 1
  name                = "${azurerm_kubernetes_cluster.this.name}-ServiceAccount-${local.keyvault-ns}-${local.keyvault-sa_name}"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.keyvault.id
  subject             = "system:serviceaccount:${local.keyvault-ns}:${local.keyvault-sa_name}"
}

data "azurerm_key_vault" "keyvault" {
  name                = var.global_config.global.certificate_keyvault.name
  resource_group_name = var.global_config.global.certificate_keyvault.resource_group_name
}

resource "azurerm_role_assignment" "csi_driver_keyvault" {
  principal_id                     = azurerm_user_assigned_identity.keyvault.principal_id
  role_definition_name             = "Key Vault Certificate User"
  scope                            = data.azurerm_key_vault.keyvault.id
  skip_service_principal_aad_check = true
}
