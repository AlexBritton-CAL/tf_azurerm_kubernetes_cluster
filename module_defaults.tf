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
      private_dns_zone_id        = "/subscriptions/31b3d3dc-ce6e-4757-ad94-4111b7c4240e/resourceGroups/infcorp_azuks_private_dns_zones_rg/providers/Microsoft.Network/privateDnsZones/privatelink.uksouth.azmk8s.io" # UPDATE LATER - Provide your private DNS zone ID
      dns_prefix_private_cluster = replace("${var.resource_prefix}-${var.instance_name}-aks", "_", "-")
      dns_prefix                 = "publicaks01" # UPDATE LATER - Provide a unique DNS prefix for public cluster

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
        name                         = "systempool"
        min_count                    = 2
        node_count                   = 2
        max_count                    = 5
        auto_scaling_enabled         = true
        vm_size                      = "Standard_B4s_v2"
        temporary_name_for_rotation  = "systemtemp"
        only_critical_addons_enabled = true
        zones                        = ["1", "2", "3"]                                                                                                                                                             # Deploy across availability zones
        vnet_subnet_id               = "/subscriptions/7a6ebd58-54ee-4885-88d7-7258df76bacc/resourceGroups/np-spok2-uks-network-rg/providers/Microsoft.Network/virtualNetworks/np-spok2-uks-vnet/subnets/aks-snet" # UPDATE LATER - Provide subnet ID if using existing VNet
        node_public_ip_enabled       = false

        upgrade_settings = {
          max_surge = "10%"
        }

        tags = {}
      }

      identity = {
        type         = "UserAssigned" # Use user-assigned managed identity
        identity_ids = [azurerm_user_assigned_identity.cluster_identity[each.key].id] # User-assigned identities (null for system-assigned)
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

