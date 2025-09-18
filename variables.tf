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
