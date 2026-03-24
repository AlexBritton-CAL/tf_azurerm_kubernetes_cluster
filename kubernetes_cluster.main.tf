locals {
  location = coalesce(try(var.location, null), try(var.config.location, null), var.global_config.global.location)

  kube_defaults = local.module_defaults.kubernetes_cluster

  kubernetes_cluster_name = try(var.config.generate_name, false) ? "${var.resource_prefix}-${var.instance_name}-aks" : try(var.config.name, var.name)

  acr_connected = try(var.config.container_registry.name, null) != null ? 1 : 0

  service_mesh_profile = merge(try(var.config.service_mesh_profile, null), local.kube_defaults.service_mesh_profile)
}

data "azurerm_client_config" "this" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                   = local.kubernetes_cluster_name
  location               = local.location
  resource_group_name    = var.resource_group_name
  node_resource_group    = coalesce(try(var.config.node_resource_group_name, null), local.kube_defaults.node_resource_group)
  oidc_issuer_enabled    = coalesce(try(var.config.oidc_issuer_enabled, null), local.kube_defaults.oidc_issuer_enabled)
  local_account_disabled = coalesce(try(var.config.local_account_disabled, null), local.kube_defaults.local_account_disabled)

  private_cluster_enabled    = coalesce(try(var.config.private_cluster_enabled, null), local.kube_defaults.private_cluster_enabled)
  private_dns_zone_id        = local.kube_defaults.private_dns_zone_id
  dns_prefix_private_cluster = coalesce(try(var.config.dns_prefix_private_cluster, null), local.kube_defaults.dns_prefix_private_cluster)
  dns_prefix                 = try(var.config.dns_prefix, null) # no default value, as the dns prefix is required for public clusters

  automatic_upgrade_channel = coalesce(try(var.config.automatic_upgrade_channel, null), local.kube_defaults.automatic_upgrade_channel)
  workload_identity_enabled = coalesce(try(var.config.workload_identity_enabled, null), local.kube_defaults.workload_identity_enabled)

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = coalesce(try(var.config.azure_active_directory_role_based_access_control.azure_rbac_enabled, null), local.kube_defaults.azure_active_directory_role_based_access_control.azure_rbac_enabled)
    tenant_id          = coalesce(try(var.config.azure_active_directory_role_based_access_control.tenant_id, null), local.kube_defaults.azure_active_directory_role_based_access_control.tenant_id)
  }

  network_profile {
    network_plugin      = coalesce(try(var.config.network_profile.network_plugin, null), local.kube_defaults.network_profile.network_plugin)
    network_plugin_mode = coalesce(try(var.config.network_profile.network_plugin_mode, null), local.kube_defaults.network_profile.network_plugin_mode)
    service_cidr        = coalesce(try(var.config.network_profile.service_cidr, null), local.kube_defaults.network_profile.service_cidr)
    pod_cidr            = coalesce(try(var.config.network_profile.pod_cidr, null), local.kube_defaults.network_profile.pod_cidr)
    dns_service_ip      = coalesce(try(var.config.network_profile.dns_service_ip, null), local.kube_defaults.network_profile.dns_service_ip)
    network_data_plane  = coalesce(try(var.config.network_profile.network_data_plane, null), local.kube_defaults.network_profile.network_data_plane)
    network_policy      = coalesce(try(var.config.network_profile.network_policy, null), local.kube_defaults.network_profile.network_policy)
  }

  dynamic "service_mesh_profile" {
    for_each = local.service_mesh_profile.mode == "Istio" ? [1] : []
    content {
      mode                             = coalesce(try(var.config.service_mesh_profile.mode, null), local.kube_defaults.service_mesh_profile.mode)
      internal_ingress_gateway_enabled = coalesce(try(var.config.service_mesh_profile.internal_ingress_gateway_enabled, null), local.kube_defaults.service_mesh_profile.internal_ingress_gateway_enabled)
      external_ingress_gateway_enabled = coalesce(try(var.config.service_mesh_profile.external_ingress_gateway_enabled, null), local.kube_defaults.service_mesh_profile.external_ingress_gateway_enabled)
      revisions                        = coalesce(try(var.config.service_mesh_profile.revisions, null), local.kube_defaults.service_mesh_profile.revisions)
    }
  }

  default_node_pool {
    name                         = coalesce(try(var.config.default_node_pool.name, null), local.kube_defaults.default_node_pool.name)
    min_count                    = coalesce(try(var.config.default_node_pool.min_count, null), local.kube_defaults.default_node_pool.min_count)
    node_count                   = coalesce(try(var.config.default_node_pool.node_count, null), local.kube_defaults.default_node_pool.node_count)
    max_count                    = coalesce(try(var.config.default_node_pool.max_count, null), local.kube_defaults.default_node_pool.max_count)
    auto_scaling_enabled         = coalesce(try(var.config.default_node_pool.auto_scaling_enabled, null), local.kube_defaults.default_node_pool.auto_scaling_enabled)
    vm_size                      = coalesce(try(var.config.default_node_pool.vm_size, null), local.kube_defaults.default_node_pool.vm_size)
    temporary_name_for_rotation  = coalesce(try(var.config.default_node_pool.temporary_name_for_rotation, null), local.kube_defaults.default_node_pool.temporary_name_for_rotation)
    only_critical_addons_enabled = coalesce(try(var.config.default_node_pool.only_critical_addons_enabled, null), local.kube_defaults.default_node_pool.only_critical_addons_enabled)
    zones                        = coalesce(try(var.config.default_node_pool.zones, null), local.kube_defaults.default_node_pool.zones)
    vnet_subnet_id               = coalesce(try(var.config.default_node_pool.vnet_subnet_id, null), local.kube_defaults.default_node_pool.vnet_subnet_id)
    node_public_ip_enabled       = coalesce(try(var.config.default_node_pool.node_public_ip_enabled, null), local.kube_defaults.default_node_pool.node_public_ip_enabled)
    upgrade_settings {
      max_surge = coalesce(try(var.config.default_node_pool.upgrade_settings.max_surge, null), local.kube_defaults.default_node_pool.upgrade_settings.max_surge)
    }
    tags = coalesce(try(var.config.default_node_pool.tags, null), local.kube_defaults.default_node_pool.tags)
  }

  identity {
    type         = local.kube_defaults.identity.type
    identity_ids = local.kube_defaults.identity.type == "UserAssigned" ? [azurerm_user_assigned_identity.cluster_identity.id] : []
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  kubernetes_version = local.kube_defaults.kubernetes_version
  tags               = merge(local.kube_defaults.tags, try(var.config.tags, {}))

  maintenance_window_auto_upgrade {
    frequency   = coalesce(try(var.config.maintenance_window_auto_upgrade.frequency, null), local.kube_defaults.maintenance_window_auto_upgrade.frequency)
    interval    = coalesce(try(var.config.maintenance_window_auto_upgrade.interval, null), local.kube_defaults.maintenance_window_auto_upgrade.interval)
    duration    = coalesce(try(var.config.maintenance_window_auto_upgrade.duration, null), local.kube_defaults.maintenance_window_auto_upgrade.duration)
    day_of_week = coalesce(try(var.config.maintenance_window_auto_upgrade.day_of_week, null), local.kube_defaults.maintenance_window_auto_upgrade.day_of_week)
    start_time  = coalesce(try(var.config.maintenance_window_auto_upgrade.start_time, null), local.kube_defaults.maintenance_window_auto_upgrade.start_time)
    utc_offset  = coalesce(try(var.config.maintenance_window_auto_upgrade.utc_offset, null), local.kube_defaults.maintenance_window_auto_upgrade.utc_offset)
  }

  maintenance_window_node_os {
    frequency   = coalesce(try(var.config.maintenance_window_node_os.frequency, null), local.kube_defaults.maintenance_window_node_os.frequency)
    interval    = coalesce(try(var.config.maintenance_window_node_os.interval, null), local.kube_defaults.maintenance_window_node_os.interval)
    duration    = coalesce(try(var.config.maintenance_window_node_os.duration, null), local.kube_defaults.maintenance_window_node_os.duration)
    day_of_week = coalesce(try(var.config.maintenance_window_node_os.day_of_week, null), local.kube_defaults.maintenance_window_node_os.day_of_week)
    start_time  = coalesce(try(var.config.maintenance_window_node_os.start_time, null), local.kube_defaults.maintenance_window_node_os.start_time)
    utc_offset  = coalesce(try(var.config.maintenance_window_node_os.utc_offset, null), local.kube_defaults.maintenance_window_node_os.utc_offset)
  }
  workload_autoscaler_profile {
    keda_enabled                    = coalesce(try(var.config.workload_autoscaler_profile.keda_enabled, null), local.kube_defaults.workload_autoscaler_profile.keda_enabled)
    vertical_pod_autoscaler_enabled = coalesce(try(var.config.workload_autoscaler_profile.vertical_pod_autoscaler_enabled, null), local.kube_defaults.workload_autoscaler_profile.vertical_pod_autoscaler_enabled)
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = coalesce(try(var.config.key_vault_secrets_provider.secret_rotation_enabled, null), local.kube_defaults.key_vault_secrets_provider.secret_rotation_enabled)
    secret_rotation_interval = coalesce(try(var.config.key_vault_secrets_provider.secret_rotation_interval, null), local.kube_defaults.key_vault_secrets_provider.secret_rotation_interval)
  }

  lifecycle {
    ignore_changes = [
      microsoft_defender,
      azure_policy_enabled
    ]

    precondition {
      condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-_]{0,61}[a-zA-Z0-9])?$", local.kubernetes_cluster_name))
      error_message = "The name must be between 1 and 63 characters long, alphanumerics, underscores, and hyphens, start and end with alphanumeric, cluster names must be unique within a resource group."
    }
  }
}

module "azurerm_kubernetes_cluster_node_pool" {
  for_each                      = try(var.config.node_pools, {})
  source                        = "./modules/cluster_node_pool"
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
  name                = local.kube_defaults.private_link_service.name
  resource_group_name = azurerm_kubernetes_cluster.this.resource_group_name
  location            = local.location

  # auto_approval_subscription_ids              = ["00000000-0000-0000-0000-000000000000"]
  # visibility_subscription_ids                 = ["00000000-0000-0000-0000-000000000000"]
  load_balancer_frontend_ip_configuration_ids = [data.azurerm_lb.kubernetes_internal.frontend_ip_configuration[0].id]

  nat_ip_configuration {
    name      = "primary"
    subnet_id = local.kube_defaults.private_link_service.subnet_id
    primary   = true
  }
  lifecycle {
    ignore_changes = [load_balancer_frontend_ip_configuration_ids]
  }
}

# FIX ME: This is a workaround to create an A record for the internal load balancer in the private DNS zone, as AKS does not automatically create this record for private clusters, which breaks connectivity to the cluster.
# This should be removed once this is supported natively by AKS.
# resource "azurerm_private_dns_a_record" "load_balancer_a_record" {
#   name                = "*"
#   zone_name           = var.global_config.global.private_dns_zone.name
#   resource_group_name = var.global_config.global.private_dns_zone.resource_group_name
#   ttl                 = 300
#   records             = [data.azurerm_lb.kubernetes_internal.frontend_ip_configuration[0].private_ip_address]
#   provider            = azurerm.private_dns
# }

