locals {
  np_defaults = local.module_defaults.kubernetes_cluster_node_pool
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  name                  = var.name
  kubernetes_cluster_id = var.azurerm_kubernetes_cluster_id

  node_count = coalesce(try(var.config.node_count, null), local.np_defaults.node_count)

  min_count            = coalesce(try(var.config.min_count, null), local.np_defaults.min_count)
  max_count            = coalesce(try(var.config.max_count, null), local.np_defaults.max_count)
  auto_scaling_enabled = coalesce(try(var.config.auto_scaling_enabled, null), local.np_defaults.auto_scaling_enabled)

  vm_size  = coalesce(try(var.config.vm_size, null), local.np_defaults.vm_size)
  max_pods = coalesce(try(var.config.max_pods, null), local.np_defaults.max_pods)
  zones    = coalesce(try(var.config.zones, null), local.np_defaults.zones)

  temporary_name_for_rotation = coalesce(try(var.config.temporary_name_for_rotation, null), local.np_defaults.temporary_name_for_rotation)

  node_public_ip_enabled = coalesce(try(var.config.node_public_ip_enabled, null), local.np_defaults.node_public_ip_enabled)

  vnet_subnet_id = coalesce(try(var.config.vnet_subnet_id, null), local.np_defaults.vnet_subnet_id)

  upgrade_settings {
    drain_timeout_in_minutes      = coalesce(try(var.config.upgrade_settings.drain_timeout_in_minutes, null), local.np_defaults.upgrade_settings.drain_timeout_in_minutes)
    max_surge                     = coalesce(try(var.config.upgrade_settings.max_surge, null), local.np_defaults.upgrade_settings.max_surge)
    node_soak_duration_in_minutes = coalesce(try(var.config.upgrade_settings.node_soak_duration_in_minutes, null), local.np_defaults.upgrade_settings.node_soak_duration_in_minutes)
  }

  tags = merge(try(var.global_config.global.tags, {}), local.np_defaults.tags, try(var.config.tags, {}))

  lifecycle {
    ignore_changes = [node_count]
  }
}
