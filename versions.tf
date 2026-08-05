terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 4.81.0"
      configuration_aliases = [azurerm.privatelink_dns, azurerm.public_dns, azurerm.private_dns]
    }
  }
  required_version = ">= 1.14.0"
}