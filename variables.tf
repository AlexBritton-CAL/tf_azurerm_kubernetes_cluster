variable "name" {
  type        = string
  description = "The name of this resource."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-_]{0,61}[a-zA-Z0-9])?$", var.name))
    error_message = "The name must be between 1 and 63 characters long and can only contain lowercase letters, numbers and hyphens."
  }
}

variable "generate_name" {
  type        = bool
  default     = true
  description = "Whether to generate the name of the resource using the resource prefix and instance name."
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

variable "automatic_upgrade_channel" {
  type        = string
  default     = null
  description = "The automatic upgrade channel for the Kubernetes cluster."
}

variable "local_account_disabled" {
  type        = bool
  default     = null
  description = "Whether or not the local account is disabled for the Kubernetes cluster."
}

variable "maintenance_window_node_os" {
  type = object({
    frequency   = optional(string)
    interval    = optional(string)
    duration    = optional(number)
    day_of_week = optional(string)
    start_time = optional(string)
    utc_offset = optional(string)
  })
  default     = null
  description = "values for maintenance window node os"
}

variable "maintenance_window_auto_upgrade" {
  type = object({
    frequency   = optional(string)
    interval    = optional(string)
    duration    = optional(number)
    day_of_week = optional(string)
    start_time  = optional(string)
    utc_offset  = optional(string)
  })
  default     = {}
  description = "values for maintenance window auto upgrade"
}

variable "default_node_pool" {
  type = object({
    name                         = optional(string)
    min_count                    = optional(number)
    node_count                   = optional(number)
    max_count                    = optional(number)
    auto_scaling_enabled         = optional(bool)
    vm_size                      = optional(string)
    temporary_name_for_rotation  = optional(string)
    only_critical_addons_enabled = optional(string)
    zones                        = optional(list(string))
    vnet_subnet_id               = optional(string)
    node_public_ip_enabled       = optional(bool)

    upgrade_settings = object({
      max_surge = optional(string, "10%")
    })
    tags = optional(map(string), {})

  })
  description = "Required. The default node pool for the Kubernetes cluster."
  default = {
    upgrade_settings = {}
  }
}

variable "network_profile" {
  type = object({
    network_plugin      = optional(string)
    network_plugin_mode = optional(string)
    service_cidr        = optional(string)
    pod_cidr            = optional(string)
    dns_service_ip      = optional(string)
    network_data_plane  = optional(string)
    network_policy      = optional(string)
  })
  description = "The network profile for the Kubernetes cluster."
  default     = {}
}

variable "service_mesh_profile" {
  type = object({
    mode                             = optional(string)
    internal_ingress_gateway_enabled = optional(bool)
    external_ingress_gateway_enabled = optional(bool)
    revisions                        = optional(list(string))
  })
  description = "The service mesh profile for the Kubernetes cluster."
  default     = {}
}

variable "azure_active_directory_role_based_access_control" {
  type = object({
    tenant_id              = optional(string)
    admin_group_object_ids = optional(list(string))
    azure_rbac_enabled     = optional(bool)
  })
  default     = {}
  description = "The Azure Active Directory role-based access control for the Kubernetes cluster."
}

variable "workload_autoscaler_profile" {
  type = object({
    keda_enabled = optional(bool)
    vertical_pod_autoscaler_enabled = optional(bool)
  })
  default     = {}
  description = "The workload autoscaler profile for the Kubernetes cluster."
}

variable "key_vault_secrets_provider" {
  type = object({
    secret_rotation_enabled  = optional(bool)
    secret_rotation_interval = optional(string)
  })
  default     = {}
  description = "The key vault secrets provider for the Kubernetes cluster. Either rotation enabled or rotation interval must be specified."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}