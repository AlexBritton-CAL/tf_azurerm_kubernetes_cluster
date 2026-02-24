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

variable "node_pools" {
  type = map(object({
    name                        = string
    vm_size                     = string
    auto_scaling_enabled        = optional(bool, false)
    max_count                   = optional(number)
    min_count                   = optional(number)
    node_count                  = optional(number)
    max_pods                    = optional(number)
    tags                        = optional(map(string))
    zones                       = optional(list(string))
    temporary_name_for_rotation = optional(string)
    upgrade_settings = optional(object({
      drain_timeout_in_minutes      = optional(number)
      node_soak_duration_in_minutes = optional(number)
      max_surge                     = string
    }))

  }))
  default     = {}
  description = "Optional. The additional node pools for the Kubernetes cluster."
}