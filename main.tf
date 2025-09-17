locals {

  kubernetes_cluster_shallow = merge(local.module_defaults.kubernetes_cluster, var.config)

  kubernetes_cluster = merge(
    local.kubernetes_cluster_shallow,
    {
      default_node_pool               = merge(local.module_defaults.kubernetes_cluster.default_node_pool, try(var.config.default_node_pool, {}))
      maintenance_window_auto_upgrade = merge(local.module_defaults.kubernetes_cluster.maintenance_window_auto_upgrade, try(var.config.maintenance_window_auto_upgrade, {}))
      maintenance_window_node_os      = merge(local.module_defaults.kubernetes_cluster.maintenance_window_node_os, try(var.config.maintenance_window_node_os, {}))
      workload_autoscaler_profile     = merge(local.module_defaults.kubernetes_cluster.workload_autoscaler_profile, try(var.config.workload_autoscaler_profile, {}))      
      tags                            = merge(var.global_config.global.tags, local.module_defaults.kubernetes_cluster.tags, try(var.config.tags, {}))
    }
  )

  kubernetes_cluster_name = local.kubernetes_cluster.generate_name ? "${var.resource_prefix}-${var.instance_name}-aks" : var.name
}

output "kubernetes_cluster" {
  value = local.kubernetes_cluster
}

data "azurerm_client_config" "this" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                   = local.kubernetes_cluster_name
  location               = try(local.kubernetes_cluster.location, var.global_config.global.location)
  resource_group_name    = var.resource_group_name
  node_resource_group    = local.kubernetes_cluster.node_resource_group
  oidc_issuer_enabled    = local.kubernetes_cluster.oidc_issuer_enabled
  local_account_disabled = local.kubernetes_cluster.local_account_disabled

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = local.kubernetes_cluster.azure_active_directory_role_based_access_control.azure_rbac_enabled
    tenant_id          = local.kubernetes_cluster.azure_active_directory_role_based_access_control.tenant_id
  }

  private_cluster_enabled    = local.kubernetes_cluster.private_cluster_enabled
  private_dns_zone_id        = local.kubernetes_cluster.private_dns_zone_id
  dns_prefix_private_cluster = local.kubernetes_cluster.dns_prefix_private_cluster
  dns_prefix                 = local.kubernetes_cluster.private_cluster_enabled ? null : local.kubernetes_cluster.dns_prefix

  automatic_upgrade_channel = local.kubernetes_cluster.automatic_upgrade_channel

  workload_identity_enabled = local.kubernetes_cluster.workload_identity_enabled

  network_profile {
    network_plugin      = local.kubernetes_cluster.network_profile.network_plugin
    network_plugin_mode = local.kubernetes_cluster.network_profile.network_plugin_mode
    service_cidr        = local.kubernetes_cluster.network_profile.service_cidr
    pod_cidr            = local.kubernetes_cluster.network_profile.pod_cidr
    dns_service_ip      = local.kubernetes_cluster.network_profile.dns_service_ip
    network_data_plane  = local.kubernetes_cluster.network_profile.network_data_plane
    network_policy      = local.kubernetes_cluster.network_profile.network_policy
  }

  dynamic "service_mesh_profile" {
    for_each = local.kubernetes_cluster.service_mesh_profile.service_mesh_enabled == true ? [1] : []
    content {
      mode                             = local.kubernetes_cluster.service_mesh_profile.mode
      internal_ingress_gateway_enabled = local.kubernetes_cluster.service_mesh_profile.internal_ingress_gateway_enabled
      external_ingress_gateway_enabled = local.kubernetes_cluster.service_mesh_profile.external_ingress_gateway_enabled
      revisions                        = local.kubernetes_cluster.service_mesh_profile.revisions
    }
  }

  default_node_pool {
    name                         = local.kubernetes_cluster.default_node_pool.name
    min_count                    = local.kubernetes_cluster.default_node_pool.min_count
    node_count                   = local.kubernetes_cluster.default_node_pool.node_count
    max_count                    = local.kubernetes_cluster.default_node_pool.max_count
    auto_scaling_enabled         = local.kubernetes_cluster.default_node_pool.auto_scaling_enabled
    vm_size                      = local.kubernetes_cluster.default_node_pool.vm_size
    temporary_name_for_rotation  = local.kubernetes_cluster.default_node_pool.temporary_name_for_rotation
    only_critical_addons_enabled = local.kubernetes_cluster.default_node_pool.only_critical_addons_enabled
    zones                        = local.kubernetes_cluster.default_node_pool.zones
    vnet_subnet_id               = local.kubernetes_cluster.default_node_pool.vnet_subnet_id
    node_public_ip_enabled       = local.kubernetes_cluster.default_node_pool.node_public_ip_enabled


    upgrade_settings {
      max_surge = local.kubernetes_cluster.default_node_pool.upgrade_settings.max_surge
    }

    tags = local.kubernetes_cluster.default_node_pool.tags
  }

  identity {
    type         = local.kubernetes_cluster.identity.type
    identity_ids = local.kubernetes_cluster.identity.type == "UserAssigned" ? [azurerm_user_assigned_identity.cluster_identity.id] : []
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  kubernetes_version = local.kubernetes_cluster.kubernetes_version
  tags               = local.kubernetes_cluster.tags

  maintenance_window_auto_upgrade {
    frequency   = local.kubernetes_cluster.maintenance_window_auto_upgrade.frequency
    interval    = local.kubernetes_cluster.maintenance_window_auto_upgrade.interval
    duration    = local.kubernetes_cluster.maintenance_window_auto_upgrade.duration
    day_of_week = local.kubernetes_cluster.maintenance_window_auto_upgrade.day_of_week
    start_time  = local.kubernetes_cluster.maintenance_window_auto_upgrade.start_time
    utc_offset  = local.kubernetes_cluster.maintenance_window_auto_upgrade.utc_offset
  }

  maintenance_window_node_os {
    frequency   = local.kubernetes_cluster.maintenance_window_node_os.frequency
    interval    = local.kubernetes_cluster.maintenance_window_node_os.interval
    duration    = local.kubernetes_cluster.maintenance_window_node_os.duration
    day_of_week = local.kubernetes_cluster.maintenance_window_node_os.day_of_week
    start_time  = local.kubernetes_cluster.maintenance_window_node_os.start_time
    utc_offset  = local.kubernetes_cluster.maintenance_window_node_os.utc_offset
  }
  workload_autoscaler_profile {
    keda_enabled                    = local.kubernetes_cluster.workload_autoscaler_profile.keda_enabled
    vertical_pod_autoscaler_enabled = local.kubernetes_cluster.workload_autoscaler_profile.vertical_pod_autoscaler_enabled
  }
}

module "azurerm_kubernetes_cluster_node_pool" {
  for_each                      = local.kubernetes_cluster.node_pools
  source                        = "git::https://github.com/AlexBritton-CAL/ts_azurerm_kubernetes_cluster_node_pool.git"
  name                          = each.key
  config                        = each.value
  global_config                 = var.global_config
  azurerm_kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
}

data "azurerm_lb" "kubernetes_internal" {
  name                = "kubernetes-internal"
  resource_group_name = regex("[^/]+$", azurerm_kubernetes_cluster.this.node_resource_group_id)

  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
}

data "azurerm_container_registry" "this" {
  name                = local.kubernetes_cluster.container_registry.name
  resource_group_name = local.kubernetes_cluster.container_registry.resource_group_name
}