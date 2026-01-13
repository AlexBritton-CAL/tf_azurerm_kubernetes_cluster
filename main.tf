locals {

  kubernetes_cluster_shallow = merge(local.module_defaults.kubernetes_cluster, var.config)

  kubernetes_cluster = merge(
    local.kubernetes_cluster_shallow,
    {
      default_node_pool = merge(local.module_defaults.kubernetes_cluster.default_node_pool, try(var.default_node_pool, {}), try(var.config.default_node_pool, {}))
      network_profile   = merge(try(var.config.network_profile, {}), try(var.network_profile, {}))
      # network_profile                    = merge(local.module_defaults.kubernetes_cluster.network_profile, try(var.config.network_profile, {}), try(var.network_profile, {}))
      maintenance_window_auto_upgrade = merge(local.module_defaults.kubernetes_cluster.maintenance_window_auto_upgrade, try(var.config.maintenance_window_auto_upgrade, {}), try(var.maintenance_window_auto_upgrade, {}))
      maintenance_window_node_os      = merge(local.module_defaults.kubernetes_cluster.maintenance_window_node_os, try(var.config.maintenance_window_node_os, {}), try(var.maintenance_window_node_os, {}))
      workload_autoscaler_profile     = merge(local.module_defaults.kubernetes_cluster.workload_autoscaler_profile, try(var.config.workload_autoscaler_profile, {}))
      tags                            = merge(try(var.global_config.global.tags, {}), local.module_defaults.kubernetes_cluster.tags, try(var.config.tags, {}))
    }
  )

  kube_default = local.module_defaults.kubernetes_cluster

  kubernetes_cluster_name = local.kubernetes_cluster.generate_name ? "${var.resource_prefix}-${var.instance_name}-aks" : var.name

  acr_connected = try(local.kubernetes_cluster.container_registry.name, "") != "" ? 1 : 0
}

data "azurerm_client_config" "this" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                   = local.kubernetes_cluster_name
  location               = coalesce(var.location, null, try(local.kube_default.location, null), var.global_config.global.location)
  resource_group_name    = var.resource_group_name
  node_resource_group    = coalesce(local.kube_default.node_resource_group, var.node_resource_group_name, null)
  oidc_issuer_enabled    = coalesce(local.kube_default.oidc_issuer_enabled, var.oidc_issuer_enabled, null)
  local_account_disabled = local.kube_default.local_account_disabled

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = local.kube_default.azure_active_directory_role_based_access_control.azure_rbac_enabled
    tenant_id          = local.kube_default.azure_active_directory_role_based_access_control.tenant_id
  }

  private_cluster_enabled    = coalesce(local.kube_default.private_cluster_enabled, try(var.private_cluster_enabled, null))
  private_dns_zone_id        = local.kube_default.private_dns_zone_id
  dns_prefix_private_cluster = local.kube_default.dns_prefix_private_cluster
  dns_prefix                 = local.kube_default.private_cluster_enabled ? null : local.kube_default.dns_prefix

  automatic_upgrade_channel = local.kube_default.automatic_upgrade_channel

  workload_identity_enabled = local.kube_default.workload_identity_enabled

  network_profile {
    network_plugin      = coalesce(local.kube_default.network_profile.network_plugin, var.network_profile.network_plugin)
    network_plugin_mode = coalesce(local.kube_default.network_profile.network_plugin_mode, var.network_profile.network_plugin_mode)
    service_cidr        = coalesce(local.kube_default.network_profile.service_cidr, var.network_profile.service_cidr)
    pod_cidr            = coalesce(local.kube_default.network_profile.pod_cidr, var.network_profile.pod_cidr)
    dns_service_ip      = coalesce(local.kube_default.network_profile.dns_service_ip, var.network_profile.dns_service_ip)
    network_data_plane  = coalesce(local.kube_default.network_profile.network_data_plane, var.network_profile.network_data_plane)
    network_policy      = coalesce(local.kube_default.network_profile.network_policy, var.network_profile.network_policy)
  }

  dynamic "service_mesh_profile" {
    for_each = local.kubernetes_cluster.service_mesh_profile.mode == "Istio" ? [1] : []
    content {
      mode                             = local.kubernetes_cluster.service_mesh_profile.mode
      internal_ingress_gateway_enabled = local.kubernetes_cluster.service_mesh_profile.internal_ingress_gateway_enabled
      external_ingress_gateway_enabled = local.kubernetes_cluster.service_mesh_profile.external_ingress_gateway_enabled
      revisions                        = local.kubernetes_cluster.service_mesh_profile.revisions
    }
  }

  default_node_pool {
    name                         = coalesce(local.kubernetes_cluster.default_node_pool.name, var.default_node_pool.name)
    min_count                    = coalesce(local.kubernetes_cluster.default_node_pool.min_count, var.default_node_pool.min_count)
    node_count                   = coalesce(local.kubernetes_cluster.default_node_pool.node_count, var.default_node_pool.node_count)
    max_count                    = coalesce(local.kubernetes_cluster.default_node_pool.max_count, var.default_node_pool.max_count)
    auto_scaling_enabled         = coalesce(local.kubernetes_cluster.default_node_pool.auto_scaling_enabled, var.default_node_pool.auto_scaling_enabled)
    vm_size                      = coalesce(local.kubernetes_cluster.default_node_pool.vm_size, var.default_node_pool.vm_size)
    temporary_name_for_rotation  = coalesce(local.kubernetes_cluster.default_node_pool.temporary_name_for_rotation, var.default_node_pool.temporary_name_for_rotation)
    only_critical_addons_enabled = coalesce(local.kubernetes_cluster.default_node_pool.only_critical_addons_enabled, var.default_node_pool.only_critical_addons_enabled)
    zones                        = coalesce(local.kubernetes_cluster.default_node_pool.zones, var.default_node_pool.zones)
    vnet_subnet_id               = coalesce(local.kubernetes_cluster.default_node_pool.vnet_subnet_id, var.default_node_pool.vnet_subnet_id)
    node_public_ip_enabled       = coalesce(local.kubernetes_cluster.default_node_pool.node_public_ip_enabled, var.default_node_pool.node_public_ip_enabled)

    upgrade_settings {
      # max_surge = local.module_defaults.kubernetes_cluster.default_node_pool.upgrade_settings.max_surge
      max_surge = coalesce(local.kubernetes_cluster.default_node_pool.upgrade_settings.max_surge, var.default_node_pool.upgrade_settings.max_surge)
    }
    tags = coalesce(local.kubernetes_cluster.default_node_pool.tags, var.default_node_pool.tags)
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
  tags               = merge(local.kubernetes_cluster.tags, var.tags)

  maintenance_window_auto_upgrade {
    frequency   = coalesce(local.kubernetes_cluster.maintenance_window_auto_upgrade.frequency, var.maintenance_window_auto_upgrade.frequency)
    interval    = coalesce(local.kubernetes_cluster.maintenance_window_auto_upgrade.interval, var.maintenance_window_auto_upgrade.interval)
    duration    = coalesce(local.kubernetes_cluster.maintenance_window_auto_upgrade.duration, var.maintenance_window_auto_upgrade.duration)
    day_of_week = coalesce(local.kubernetes_cluster.maintenance_window_auto_upgrade.day_of_week, var.maintenance_window_auto_upgrade.day_of_week)
    start_time  = coalesce(local.kubernetes_cluster.maintenance_window_auto_upgrade.start_time, var.maintenance_window_auto_upgrade.start_time)
    utc_offset  = coalesce(local.kubernetes_cluster.maintenance_window_auto_upgrade.utc_offset, var.maintenance_window_auto_upgrade.utc_offset)
  }

  maintenance_window_node_os {
    frequency   = coalesce(local.kubernetes_cluster.maintenance_window_node_os.frequency, var.maintenance_window_node_os.frequency)
    interval    = coalesce(local.kubernetes_cluster.maintenance_window_node_os.interval, var.maintenance_window_node_os.interval)
    duration    = coalesce(local.kubernetes_cluster.maintenance_window_node_os.duration, var.maintenance_window_node_os.duration)
    day_of_week = coalesce(local.kubernetes_cluster.maintenance_window_node_os.day_of_week, var.maintenance_window_node_os.day_of_week)
    start_time  = coalesce(local.kubernetes_cluster.maintenance_window_node_os.start_time, var.maintenance_window_node_os.start_time)
    utc_offset  = coalesce(local.kubernetes_cluster.maintenance_window_node_os.utc_offset, var.maintenance_window_node_os.utc_offset)
  }
  workload_autoscaler_profile {
    keda_enabled                    = local.kubernetes_cluster.workload_autoscaler_profile.keda_enabled
    vertical_pod_autoscaler_enabled = local.kubernetes_cluster.workload_autoscaler_profile.vertical_pod_autoscaler_enabled
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = try(local.kubernetes_cluster.key_vault_secrets_provider.secret_rotation_enabled, null)
    secret_rotation_interval = try(local.kubernetes_cluster.key_vault_secrets_provider.secret_rotation_interval, null)
  }

  lifecycle {
    ignore_changes = [
      microsoft_defender,
      azure_policy_enabled
    ]
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

resource "azurerm_private_link_service" "aks_lb_privatelink" {
  name                = local.kubernetes_cluster.private_link_service.name
  resource_group_name = azurerm_kubernetes_cluster.this.resource_group_name
  location            = azurerm_kubernetes_cluster.this.location

  # auto_approval_subscription_ids              = ["00000000-0000-0000-0000-000000000000"]
  # visibility_subscription_ids                 = ["00000000-0000-0000-0000-000000000000"]
  load_balancer_frontend_ip_configuration_ids = [data.azurerm_lb.kubernetes_internal.frontend_ip_configuration[0].id]

  nat_ip_configuration {
    name      = "primary"
    subnet_id = local.kubernetes_cluster.private_link_service.subnet_id
    primary   = true
  }
  lifecycle {
    ignore_changes = [load_balancer_frontend_ip_configuration_ids]
  }
}

resource "azurerm_private_dns_a_record" "load_balancer_a_record" {
  name                = "*"
  zone_name           = var.global_config.global.private_dns_zone.name
  resource_group_name = var.global_config.global.private_dns_zone.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_lb.kubernetes_internal.frontend_ip_configuration[0].private_ip_address]
  provider            = azurerm.private_dns
}

