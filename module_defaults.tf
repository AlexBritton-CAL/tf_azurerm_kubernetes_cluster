locals {
  module_defaults = {
    kubernetes_cluster = {
      node_resource_group    = try(var.config.node_resource_group_name, replace(var.resource_group_name, "-rg", "-nodes-rg"))
      oidc_issuer_enabled    = true
      local_account_disabled = true

      azure_active_directory_role_based_access_control = {
        azure_rbac_enabled = true
        tenant_id          = try(var.config.defualts.tenant_id, data.azurerm_client_config.this.tenant_id)
      }

      private_cluster_enabled    = true
      private_dns_zone_id        = "/subscriptions/31b3d3dc-ce6e-4757-ad94-4111b7c4240e/resourceGroups/infcorp_azuks_private_dns_zones_rg/providers/Microsoft.Network/privateDnsZones/privatelink.uksouth.azmk8s.io" # Replace with actual default value
      dns_prefix_private_cluster = replace("${var.resource_prefix}-${var.instance_name}-aks", "_", "-")
      dns_prefix                 = "publicaks01"

      automatic_upgrade_channel = "stable"

      workload_identity_enabled = true

      network_profile = {
        network_plugin      = "azure"
        network_plugin_mode = "overlay"
        service_cidr        = "10.0.11.0/24"
        pod_cidr            = "10.244.0.0/16"
        dns_service_ip      = "10.0.11.10"
        network_data_plane  = "cilium"
        network_policy      = "cilium"
      }

      service_mesh_profile = {
        service_mesh_enabled             = true
        mode                             = "Istio"
        internal_ingress_gateway_enabled = true
        external_ingress_gateway_enabled = false
        revisions                        = ["asm-1-23"]
      }

      default_node_pool = {
        name                        = "system"
        min_count                   = 1
        node_count                  = 2
        max_count                   = 3
        auto_scaling_enabled        = true
        vm_size                     = "Standard_B4s_v2"
        temporary_name_for_rotation = "systemtemp"
        zones                       = ["1", "2", "3"] # Deploy across availability zones
        tags                        = {}
      }

      identity = {
        type         = "SystemAssigned" # Use system-assigned managed identity
        identity_ids = null             # User-assigned identities (null for system-assigned)
      }

      kubernetes_version = null # Use latest stable version (null = Azure default)

      tags = {
        ModuleTag = "ModuleValue"
        ManagedBy = "Module_Defaults"
      }

      maintenance_window_auto_upgrade = {
        frequency   = "Weekly"
        interval    = 1
        duration    = 4 # 4-hour maintenance window
        day_of_week = "Saturday"
        start_time  = "02:00"
        utc_offset  = "+00:00"
      }

      maintenance_window_node_os = {
        frequency   = "Weekly"
        interval    = 1
        duration    = 4
        day_of_week = "Sunday"
        start_time  = "02:00"
        utc_offset  = "+00:00"
      }
    }
  }
}

