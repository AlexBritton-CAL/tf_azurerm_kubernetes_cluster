locals {
  location = "uksouth"
  resource_prefix = "example"
  instance_name = "exampleinstance"

  layer_config_yaml = file("./config.yaml")
  layer_config      = yamldecode(local.layer_config_yaml)

  global_config_yaml = file("./global.yaml")
  global_config      = yamldecode(local.global_config_yaml)
}

resource "azurerm_resource_group" "this" {
  name     = "${local.resource_prefix}-${local.instance_name}-rg"
  location = local.location
}

module "azurerm_kubernetes_cluster" {
  for_each            = try(local.layer_config.azurerm_kubernetes_cluster, {})
  source              = "git::https://github.com/AlexBritton-CAL/tf_azurerm_kubernetes_cluster.git"
  name                = each.key
  config              = layer_config
  global_config       = local.global_config
  resource_group_name = azurerm_resource_group.this.name
  instance_name       = local.instance_name
  resource_prefix     = local.resource_prefix

  providers = {
    azurerm.privatelink_dns = azurerm.privatelink_dns
  }
}