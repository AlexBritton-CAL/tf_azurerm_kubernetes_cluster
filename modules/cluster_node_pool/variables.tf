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

variable "instance_name" {
  type    = string
  default = null
}

variable "layer_name" {
  type    = string
  default = null
}

variable "resource_prefix" {
  type    = string
  default = null
}

