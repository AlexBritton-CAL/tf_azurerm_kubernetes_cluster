variable "name" {
  type        = string
  description = "The name of this resource."
  default     = null

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

