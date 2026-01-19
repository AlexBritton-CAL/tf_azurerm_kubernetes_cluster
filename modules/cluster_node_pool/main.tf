locals {
  kubernetes_cluster_node_pool_shallow = merge(local.module_defaults.node_pool, var.config)

  kubernetes_cluster_node_pool = merge(
    local.kubernetes_cluster_node_pool_shallow,
    {
      upgrade_settings = merge(local.module_defaults.node_pool.upgrade_settings, try(var.config.upgrade_settings, {}))
      tags             = merge(try(var.global_config.global.tags, {}), local.module_defaults.node_pool.tags, try(var.config.tags, {}))
    }
  )
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  name                  = var.name
  kubernetes_cluster_id = var.azurerm_kubernetes_cluster_id

  node_count = local.kubernetes_cluster_node_pool.node_count

  min_count            = local.kubernetes_cluster_node_pool.min_count
  max_count            = local.kubernetes_cluster_node_pool.max_count
  auto_scaling_enabled = local.kubernetes_cluster_node_pool.auto_scaling_enabled

  vm_size  = local.kubernetes_cluster_node_pool.vm_size
  max_pods = local.kubernetes_cluster_node_pool.max_pods
  zones    = local.kubernetes_cluster_node_pool.zones

  temporary_name_for_rotation = local.kubernetes_cluster_node_pool.temporary_name_for_rotation

  node_public_ip_enabled = local.kubernetes_cluster_node_pool.node_public_ip_enabled

  vnet_subnet_id = local.kubernetes_cluster_node_pool.vnet_subnet_id

  upgrade_settings {
    drain_timeout_in_minutes      = local.kubernetes_cluster_node_pool.upgrade_settings.drain_timeout_in_minutes
    max_surge                     = local.kubernetes_cluster_node_pool.upgrade_settings.max_surge
    node_soak_duration_in_minutes = local.kubernetes_cluster_node_pool.upgrade_settings.node_soak_duration_in_minutes
  }

  tags = local.kubernetes_cluster_node_pool.tags

  lifecycle {
    ignore_changes = [node_count]
  }

}

