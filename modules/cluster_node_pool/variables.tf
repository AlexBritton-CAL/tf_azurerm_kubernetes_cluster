variable "name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "config" {
  description = "The configuration for the layer"
  type        = any
}

variable "global_config" {
  description = "The global configuration"
  type        = any
}

variable "azurerm_kubernetes_cluster_id" {
  description = "The ID of the AKS cluster"
  type        = string
}
