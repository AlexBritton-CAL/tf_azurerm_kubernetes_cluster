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

variable "resource_group_name" {
  description = "The name of the resource group for the AKS cluster"
  type        = string
  default     = null
}

variable "instance_name" {
  type    = string
  default = null
}

variable "resource_prefix" {
  type    = string
  default = null
}

variable "node_resource_group_name" {
  type        = string
  default     = null
  description = "The resource group name for the node pool."
}

variable "oidc_issuer_enabled" {
  type        = bool
  default     = false
  description = "Whether or not the OIDC issuer is enabled for the Kubernetes cluster."
}

variable "maintenance_window_node_os" {
  type = object({
    frequency    = string
    interval     = string
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(object({
      start = string
      end   = string
    }))
  })
  default     = null
  description = "values for maintenance window node os"
}

variable "maintenance_window_auto_upgrade" {
  type = object({
    frequency    = string
    interval     = string
    duration     = number
    day_of_week  = optional(string)
    day_of_month = optional(number)
    week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    start_date   = optional(string)
    not_allowed = optional(object({
      start = string
      end   = string
    }))
  })
  default     = null
  description = "values for maintenance window auto upgrade"
}