terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.25.0"
      # configuration_aliases = [azurerm.privatelink_dns, azurerm.public_dns, azurerm.private_dns]
      configuration_aliases = [azurerm.privatelink_dns]
    }
  }
  required_version = ">= 1.1.0"
}