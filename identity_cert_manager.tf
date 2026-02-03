locals {
  cert-manager-ns      = "cert-manager"
  cert-manager-sa_name = "cert-manager"
}

resource "azurerm_user_assigned_identity" "certmanager" {
  location            = azurerm_kubernetes_cluster.this.location
  name                = coalesce(try(var.config.identity.certmanager_identity, null), local.module_defaults.identity.certmanager_identity)
  resource_group_name = var.resource_group_name
}

resource "azurerm_federated_identity_credential" "certmanager" {
  name                = "${azurerm_kubernetes_cluster.this.name}-ServiceAccount-${local.cert-manager-ns}-${local.cert-manager-sa_name}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.certmanager.id
  subject             = "system:serviceaccount:${local.cert-manager-ns}:${local.cert-manager-sa_name}"
}

# FIX ME: Runners need to be able to assign these DNS roles to the identity
data "azurerm_dns_zone" "public_dns_zone" {
  name                = var.global_config.global.public_dns_zone.name
  resource_group_name = var.global_config.global.public_dns_zone.resource_group_name
  provider            = azurerm.public_dns
}

data "azurerm_dns_zone" "shadow_private_dns_zone" {
  name                = var.global_config.global.shadow_private_dns_zone.name
  resource_group_name = var.global_config.global.shadow_private_dns_zone.resource_group_name
  provider            = azurerm.public_dns
}

resource "azurerm_role_assignment" "certmanager_public_dns" {
  principal_id                     = azurerm_user_assigned_identity.certmanager.principal_id
  role_definition_name             = "DNS Zone Contributor"
  scope                            = data.azurerm_dns_zone.public_dns_zone.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "certmanager_shadow_private_dns" {
  principal_id                     = azurerm_user_assigned_identity.certmanager.principal_id
  role_definition_name             = "DNS Zone Contributor"
  scope                            = data.azurerm_dns_zone.shadow_private_dns_zone.id
  skip_service_principal_aad_check = true
}
