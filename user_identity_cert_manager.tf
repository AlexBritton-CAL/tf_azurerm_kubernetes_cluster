locals {
  cert-manager-ns      = "cert-manager"
  cert-manager-sa_name = "cert-manager"
  cert-manager-enabled = try(var.config.identity.certmanager_identity.enabled, false)
}

resource "azurerm_user_assigned_identity" "certmanager" {
  count = local.cert-manager-enabled ? 1 : 0
  location            = local.location
  name                = coalesce(try(var.config.identity.certmanager_identity.name, null), local.module_defaults.identity.certmanager_identity.name)
  resource_group_name = var.resource_group_name
}
  
resource "azurerm_federated_identity_credential" "certmanager" {
  count = local.cert-manager-enabled ? 1 : 0
  name                = "${azurerm_kubernetes_cluster.this.name}-ServiceAccount-${local.cert-manager-ns}-${local.cert-manager-sa_name}"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.certmanager[0].id
  subject             = "system:serviceaccount:${local.cert-manager-ns}:${local.cert-manager-sa_name}"
}

# FIX ME: Runners need to be able to assign these DNS roles to the identity
data "azurerm_dns_zone" "public_dns_zone" {
  count = local.cert-manager-enabled ? 1 : 0
  name                = var.global_config.global.public_dns_zone.name
  resource_group_name = var.global_config.global.public_dns_zone.resource_group_name
  provider            = azurerm.public_dns
}

data "azurerm_dns_zone" "shadow_private_dns_zone" {
  count = local.cert-manager-enabled ? 1 : 0
  name                = var.global_config.global.shadow_private_dns_zone.name
  resource_group_name = var.global_config.global.shadow_private_dns_zone.resource_group_name
  provider            = azurerm.public_dns
}

resource "azurerm_role_assignment" "certmanager_public_dns" {
  count = local.cert-manager-enabled ? 1 : 0
  principal_id                     = azurerm_user_assigned_identity.certmanager[0].principal_id
  role_definition_name             = "DNS Zone Contributor"
  scope                            = data.azurerm_dns_zone.public_dns_zone[0].id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "certmanager_shadow_private_dns" {
  count = local.cert-manager-enabled ? 1 : 0
  principal_id                     = azurerm_user_assigned_identity.certmanager[0].principal_id
  role_definition_name             = "DNS Zone Contributor"
  scope                            = data.azurerm_dns_zone.shadow_private_dns_zone[0].id
  skip_service_principal_aad_check = true
}
