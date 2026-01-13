variable "name" {
  type        = string
  description = "The name of this resource."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-_]{0,61}[a-zA-Z0-9])?$", var.name))
    error_message = "The name must be between 1 and 63 characters long and can only contain lowercase letters, numbers and hyphens."
  }
}

variable "config" {
  description = "The configuration for the layer"
  type        = any
}

variable "global_config" {
  description = "The global configuration"
  type        = any
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
  nullable    = false
}

variable "instance_name" {
  type    = string
  default = null
}

variable "resource_prefix" {
  type    = string
  default = null
}

variable "location" {
  type        = string
  default     = null
  description = "Azure region where the resource should be deployed."
}

variable "node_resource_group_name" {
  type        = string
  default     = null
  description = "The resource group name for the node pool."
}

variable "private_cluster_enabled" {
  type        = bool
  default     = true
  description = "Whether or not the cluster is a private cluster."
}

variable "oidc_issuer_enabled" {
  type        = bool
  default     = true
  description = "Whether or not the OIDC issuer is enabled for the Kubernetes cluster."
}

variable "maintenance_window_node_os" {
  type = object({
    frequency   = optional(string, "Weekly")
    interval    = optional(string, "1")
    duration    = optional(number, "4")
    day_of_week = optional(string, "Sunday")
    # day_of_month = optional(number)
    # week_index   = optional(string)
    start_time = optional(string, "02:00")
    utc_offset = optional(string, "+00:00")
    # start_date   = optional(string)
    # not_allowed = optional(object({
    # start = string
    # end   = string
    # }))
  })
  default     = null
  description = "values for maintenance window node os"
}

variable "maintenance_window_auto_upgrade" {
  type = object({
    frequency   = optional(string, "Weekly")
    interval    = optional(string, "1")
    duration    = optional(number, 4)
    day_of_week = optional(string, "Saturday")
    start_time = optional(string, "02:00")
    utc_offset = optional(string, "+00:00")
  })
  default     = null
  description = "values for maintenance window auto upgrade"
}

variable "default_node_pool" {
  type = object({
    name                         = optional(string, "systempool")
    min_count                    = optional(number, 2)
    node_count                   = optional(number, 2)
    max_count                    = optional(number, 5)
    auto_scaling_enabled         = optional(bool, true)
    vm_size                      = optional(string, "Standard_B4s_v2")
    temporary_name_for_rotation  = optional(string, "systemtemp")
    only_critical_addons_enabled = optional(string, true)
    zones                        = optional(list(string), ["1", "2", "3"])
    vnet_subnet_id               = optional(string)
    node_public_ip_enabled       = optional(bool, false)

    upgrade_settings = optional(object({
      max_surge = optional(string, "25%")
    }))
    tags = optional(map(string), {})

  })
  description = "Required. The default node pool for the Kubernetes cluster."
  default     = null
}

variable "network_profile" {
  type = object({
    network_plugin      = optional(string, "azure")
    network_plugin_mode = optional(string, "overlay")
    service_cidr        = optional(string, "10.0.11.0/24")
    pod_cidr            = optional(string, "10.244.0.0/16")
    dns_service_ip      = optional(string, "10.0.11.10")
    network_data_plane  = optional(string, "cilium")
    network_policy      = optional(string, "cilium")
  })
  description = "The network profile for the Kubernetes cluster."
  default = {}
}

variable "service_mesh_profile" {
  type = object({
    mode                             = optional(string)
    internal_ingress_gateway_enabled = optional(bool)
    external_ingress_gateway_enabled = optional(bool)
    revisions                        = optional(list(string), [])
  })
  description = "The service mesh profile for the Kubernetes cluster."
  default     = null
}