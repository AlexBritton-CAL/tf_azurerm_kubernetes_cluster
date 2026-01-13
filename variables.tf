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
  default     = null
  description = "Whether or not the cluster is a private cluster."
}

variable "oidc_issuer_enabled" {
  type        = bool
  default     = null
  description = "Whether or not the OIDC issuer is enabled for the Kubernetes cluster."
}

variable "maintenance_window_node_os" {
  type = object({
    frequency    = optional(string)
    interval     = optional(string)
    duration     = optional(number)
    day_of_week  = optional(string)
    # day_of_month = optional(number)
    # week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
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
    frequency    = optional(string)
    interval     = optional(string)
    duration     = optional(number)
    day_of_week  = optional(string)
    # day_of_month = optional(number)
    # week_index   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    # start_date   = optional(string)
    # not_allowed = optional(object({
      # start = string
      # end   = string
    # }))
  })
  default     = null
  description = "values for maintenance window auto upgrade"
}

variable "default_node_pool" {
  type = object({
    name                          = optional(string)
    min_count                     = optional(number)
    node_count                    = optional(number)
    max_count                     = optional(number)
    auto_scaling_enabled          = optional(bool, false)
    vm_size                       = optional(string)
    temporary_name_for_rotation   = optional(string)
    only_critical_addons_enabled  = optional(string)
    zones                         = optional(list(string))
    vnet_subnet_id                = optional(string)
    node_public_ip_enabled        = optional(bool)

    # capacity_reservation_group_id = optional(string)
    # host_encryption_enabled       = optional(bool)
    # node_public_ip_enabled        = optional(bool)
    # gpu_instance                  = optional(string)
    # host_group_id                 = optional(string)
    # fips_enabled                  = optional(bool)
    # kubelet_disk_type             = optional(string)
    # max_pods                      = optional(number)
    # node_public_ip_prefix_id      = optional(string)
    # node_labels                   = optional(map(string))
    # orchestrator_version          = optional(string)
    # os_disk_size_gb               = optional(string)
    # os_disk_type                  = optional(string)
    # os_sku                        = optional(string)
    # pod_subnet_id                 = optional(string)
    # proximity_placement_group_id  = optional(string)
    # scale_down_mode               = optional(string)
    # snapshot_id                   = optional(string)
    # type                          = optional(string, "VirtualMachineScaleSets")
    # tags                          = optional(map(string))
    # ultra_ssd_enabled             = optional(bool)
    # workload_runtime              = optional(string)
    # kubelet_config = optional(object({
    #   cpu_manager_policy        = optional(string)
    #   cpu_cfs_quota_enabled     = optional(bool, true)
    #   cpu_cfs_quota_period      = optional(string)
    #   image_gc_high_threshold   = optional(number)
    #   image_gc_low_threshold    = optional(number)
    #   topology_manager_policy   = optional(string)
    #   allowed_unsafe_sysctls    = optional(set(string))
    #   container_log_max_size_mb = optional(number)
    #   container_log_max_line    = optional(number)
    #   pod_max_pid               = optional(number)
    # }))
    # linux_os_config = optional(object({
    #   sysctl_config = optional(object({
    #     fs_aio_max_nr                      = optional(number)
    #     fs_file_max                        = optional(number)
    #     fs_inotify_max_user_watches        = optional(number)
    #     fs_nr_open                         = optional(number)
    #     kernel_threads_max                 = optional(number)
    #     net_core_netdev_max_backlog        = optional(number)
    #     net_core_optmem_max                = optional(number)
    #     net_core_rmem_default              = optional(number)
    #     net_core_rmem_max                  = optional(number)
    #     net_core_somaxconn                 = optional(number)
    #     net_core_wmem_default              = optional(number)
    #     net_core_wmem_max                  = optional(number)
    #     net_ipv4_ip_local_port_range_min   = optional(number)
    #     net_ipv4_ip_local_port_range_max   = optional(number)
    #     net_ipv4_neigh_default_gc_thresh1  = optional(number)
    #     net_ipv4_neigh_default_gc_thresh2  = optional(number)
    #     net_ipv4_neigh_default_gc_thresh3  = optional(number)
    #     net_ipv4_tcp_fin_timeout           = optional(number)
    #     net_ipv4_tcp_keepalive_intvl       = optional(number)
    #     net_ipv4_tcp_keepalive_probes      = optional(number)
    #     net_ipv4_tcp_keepalive_time        = optional(number)
    #     net_ipv4_tcp_max_syn_backlog       = optional(number)
    #     net_ipv4_tcp_max_tw_buckets        = optional(number)
    #     net_ipv4_tcp_tw_reuse              = optional(bool)
    #     net_netfilter_nf_conntrack_buckets = optional(number)
    #     net_netfilter_nf_conntrack_max     = optional(number)
    #     vm_max_map_count                   = optional(number)
    #     vm_swappiness                      = optional(number)
    #     vm_vfs_cache_pressure              = optional(number)
    #   }))

    #   transparent_huge_page_enabled = optional(string)
    #   transparent_huge_page_defrag  = optional(string)
    #   swap_file_size_mb             = optional(number)
    # }))
    # node_network_profile = optional(object({
    #   application_security_group_ids = optional(list(string))
    #   node_public_ip_tags            = optional(map(string))
    #   allowed_host_ports = optional(list(object({
    #     port_end   = optional(number)
    #     port_start = optional(number)
    #     protocol   = optional(string)
    #   })))
    # }))
    upgrade_settings = optional(object({
      # drain_timeout_in_minutes      = optional(number)
      # node_soak_duration_in_minutes = optional(number)
      max_surge                     = string
    }))

  })
  description = "Required. The default node pool for the Kubernetes cluster."
  default     = null

  # validation {
  #   condition     = !var.default_node_pool.auto_scaling_enabled || var.default_node_pool.type == "VirtualMachineScaleSets"
  #   error_message = "Autoscaling on default node pools is only supported when the Kubernetes Cluster is using Virtual Machine Scale Sets type nodes."
  # }
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
  default     = null
}

variable "service_mesh_profile" {
  type = object({
    mode                             = optional(string)
    internal_ingress_gateway_enabled = optional(bool)
    external_ingress_gateway_enabled = optional(bool)
    revisions                        = optional(list(string), [])
    # certificate_authority = optional(object({
    #   key_vault_id           = string
    #   root_cert_object_name  = string
    #   cert_chain_object_name = string
    #   cert_object_name       = string
    #   key_object_name        = string
    # }))
  })
  description = "The service mesh profile for the Kubernetes cluster."
  default     = null
}