locals {
  cluster_vnet_subnet_id_prefix = "/subscriptions/${var.global_config.global.subscription_id}/resourceGroups/${var.global_config.global.spoke.network.virtual_network_resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.global_config.global.spoke.network.virtual_network_name}/subnets/"
  module_defaults = {

    identity = {
      certmanager_identity = {
        name = "${var.resource_prefix}-${var.instance_name}-aks-certmanagerid"
      }
      keyvault_identity = {
        name = "${var.resource_prefix}-${var.instance_name}-aks-keyvaultid"
      }
    }
    kubernetes_cluster = {
      node_resource_group    = try(var.config.node_resource_group_name, replace(var.resource_group_name, "-rg", "-nodes-rg"))
      oidc_issuer_enabled    = true
      local_account_disabled = true

      azure_active_directory_role_based_access_control = {
        azure_rbac_enabled = true
        tenant_id          = try(var.global_config.global.tenant_id, data.azurerm_client_config.this.tenant_id)
      }

      private_cluster_enabled    = true
      private_dns_zone_id        = "/subscriptions/${var.global_config.global.privatelink_dns_zones.subscription_id}/resourceGroups/${var.global_config.global.privatelink_dns_zones.resource_group_name}/providers/Microsoft.Network/privateDnsZones/privatelink.${local.location}.azmk8s.io"
      dns_prefix_private_cluster = replace("${var.resource_prefix}-${var.instance_name}-aks", "_", "-")
      dns_prefix                 = replace("${var.resource_prefix}-${var.instance_name}-aks", "_", "-")

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
        mode                             = "Istio"
        internal_ingress_gateway_enabled = true
        external_ingress_gateway_enabled = false
        revisions                        = ["asm-1-25"]
      }

      default_node_pool = {
        name                         = "default"
        min_count                    = 2
        node_count                   = 2
        max_count                    = 5
        auto_scaling_enabled         = true
        vm_size                      = "Standard_B4s_v2"
        temporary_name_for_rotation  = "systemtemp"
        only_critical_addons_enabled = true
        zones                        = ["1", "2", "3"] # Deploy across availability zones
        vnet_subnet_id               = "${local.cluster_vnet_subnet_id_prefix}aks-snet"
        node_public_ip_enabled       = false

        upgrade_settings = {
          max_surge = "10%"
        }

        tags = {}
      }

      identity = {
        type = "UserAssigned" # Use user-assigned managed identity
      }

      key_vault_secrets_provider = {
        secret_rotation_enabled  = true
        secret_rotation_interval = "2m"
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

      workload_autoscaler_profile = {
        keda_enabled                    = true
        vertical_pod_autoscaler_enabled = true
      }

      private_link_service = {
        name      = "plink"
        subnet_id = "${local.cluster_vnet_subnet_id_prefix}app-snet"
      }
    }
  }
}

