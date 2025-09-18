locals {
  cert-manager-ns      = "cert-manager"
  cert-manager-sa_name = "cert-manager"
}

resource "azurerm_user_assigned_identity" "certmanager" {
  location            = azurerm_kubernetes_cluster.this.location
  name                = try(local.kubernetes_cluster.identity.cluster_identity, "${var.resource_prefix}-${var.instance_name}-aks-certmanagerid")
  resource_group_name = var.resource_group_name
}

data "azurerm_dns_zone" "public_dns_zone" {
  name                = "calastonenp.com"
  resource_group_name = var.config.public_dns_zone.rg_name
  provider            = azurerm.public_dns
}

# # resource "azurerm_role_assignment" "certmanager_public_dns" {
# #   for_each                         = local.aks
# #   principal_id                     = azurerm_user_assigned_identity.certmanager[each.key].principal_id
# #   role_definition_name             = "DNS Zone Contributor"
# #   scope                            = data.azurerm_dns_zone.public_dns_zone.id
# #   skip_service_principal_aad_check = true
# # }

# resource "azurerm_role_assignment" "certmanager_private_dns" {
#   principal_id                     = azurerm_user_assigned_identity.certmanager.principal_id
#   role_definition_name             = "Private DNS Zone Contributor"
#   scope                            = data.azurerm_private_dns_zone.private_dns_zone.id
#   skip_service_principal_aad_check = true
# }

resource "azurerm_federated_identity_credential" "certmanager" {
  name                = "${azurerm_kubernetes_cluster.this.name}-ServiceAccount-${local.cert-manager-ns}-${local.cert-manager-sa_name}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.certmanager.id
  subject             = "system:serviceaccount:${local.cert-manager-ns}:${local.cert-manager-sa_name}"
}
