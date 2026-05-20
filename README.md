# azurerm_kubernetes_cluster

Deploys a private Azure Kubernetes Service (AKS) cluster with managed identities, Istio service mesh, Cilium networking, and a Private Link Service over the internal load balancer.

## Features

- Private cluster with Azure RBAC and local accounts disabled by default
- User-assigned managed identity for the cluster control plane and kubelet
- Workload identity and OIDC issuer enabled for federated credential support
- Azure CNI Overlay with Cilium data plane and network policy
- Istio service mesh add-on with internal ingress gateway
- KEDA and Vertical Pod Autoscaler enabled
- Key Vault CSI secrets provider with automatic secret rotation
- Managed identities with federated credentials pre-configured for cert-manager and Istio ingress gateway Key Vault access
- Optional ACR pull role assignment for the kubelet identity
- Private Link Service created over the AKS internal load balancer
- Wildcard DNS A record written to the private DNS zone for ingress routing
- Additional node pools via the `cluster_node_pool` submodule
- Name generation from `resource_prefix` and `instance_name`

## Usage

```hcl
module "azurerm_kubernetes_cluster" {
  for_each = try(module.layer.layer_config.azurerm_kubernetes_cluster, {})
  source   = "../modules/azurerm_kubernetes_cluster"

  providers = {
    azurerm                  = azurerm
    azurerm.privatelink_dns  = azurerm.privatelink_dns
    azurerm.public_dns       = azurerm.public_dns
    azurerm.private_dns      = azurerm.private_dns
  }

  resource_group_name = local.resource_group_name
  instance_name       = local.instance_name
  resource_prefix     = local.resource_prefix
  global_config       = local.global_config
  config              = each.value
}
```

## config.yaml

### Minimal

```yaml
azurerm_kubernetes_cluster:
  my_cluster:
    generate_name: true
```

### Full reference

```yaml
azurerm_kubernetes_cluster:
  my_cluster:
    generate_name: true                        # if false, provide name
    name: my-aks                               # explicit name, used when generate_name is false
    location: uksouth                          # overrides global_config location
    node_resource_group_name: my-nodes-rg      # overrides default derived from resource_group_name
    dns_prefix_private_cluster: my-aks         # private cluster DNS prefix
    dns_prefix: my-aks                         # public cluster DNS prefix (required when private_cluster_enabled is false)
    private_cluster_enabled: true
    oidc_issuer_enabled: true
    workload_identity_enabled: true
    local_account_disabled: true
    automatic_upgrade_channel: stable          # none | patch | stable | rapid | node-image
    kubernetes_version: null                   # null = Azure-managed latest stable
    tags:
      env: production

    azure_active_directory_role_based_access_control:
      azure_rbac_enabled: true
      tenant_id: 00000000-0000-0000-0000-000000000000

    network_profile:
      network_plugin: azure
      network_plugin_mode: overlay
      network_data_plane: cilium
      network_policy: cilium
      service_cidr: 10.0.11.0/24
      pod_cidr: 10.244.0.0/16
      dns_service_ip: 10.0.11.10

    service_mesh_profile:
      mode: Istio
      internal_ingress_gateway_enabled: true
      external_ingress_gateway_enabled: false
      revisions:
        - asm-1-25

    default_node_pool:
      name: default
      vm_size: Standard_B4s_v2
      min_count: 2
      node_count: 2
      max_count: 5
      auto_scaling_enabled: true
      only_critical_addons_enabled: true
      zones: ["1", "2", "3"]
      vnet_subnet_name: aks-snet                # subnet name within the spoke VNet; module builds the full ID (default: aks-snet)
      # vnet_subnet_id: /subscriptions/.../subnets/aks-snet  # alternative: supply the full resource ID directly
      node_public_ip_enabled: false
      temporary_name_for_rotation: systemtemp
      tags: {}
      upgrade_settings:
        max_surge: 10%

    maintenance_window_auto_upgrade:
      frequency: Weekly
      interval: 1
      duration: 4
      day_of_week: Saturday
      start_time: "02:00"
      utc_offset: "+00:00"

    maintenance_window_node_os:
      frequency: Weekly
      interval: 1
      duration: 4
      day_of_week: Sunday
      start_time: "02:00"
      utc_offset: "+00:00"

    workload_autoscaler_profile:
      keda_enabled: true
      vertical_pod_autoscaler_enabled: true

    key_vault_secrets_provider:
      secret_rotation_enabled: true
      secret_rotation_interval: 2m

    container_registry:
      name: myacr
      resource_group_name: my-acr-rg

    identity:
      certmanager_identity:
        name: my-aks-certmanagerid
      keyvault_identity:
        name: my-aks-keyvaultid

    node_pools:
      workload:
        vm_size: Standard_B4ms
        min_count: 1
        node_count: 2
        max_count: 4
        auto_scaling_enabled: true
        max_pods: 50
        zones: ["1", "2", "3"]
        vnet_subnet_name: aks-snet                # subnet name within the spoke VNet; module builds the full ID (default: aks-snet)
        # vnet_subnet_id: /subscriptions/.../subnets/aks-snet  # alternative: supply the full resource ID directly
        node_public_ip_enabled: false
        temporary_name_for_rotation: workloadtemp
        tags: {}
        upgrade_settings:
          max_surge: 10%
          drain_timeout_in_minutes: 0
          node_soak_duration_in_minutes: 0
```

## Variables

| Name | Description | Type | Required |
|---|---|---|---|
| `name` | Explicit cluster name. Used when `config.generate_name` is false | `string` | No |
| `config` | Resource configuration. See full reference above | `any` | Yes |
| `global_config` | Shared platform configuration | `any` | Yes |
| `resource_group_name` | Resource group to deploy into | `string` | Yes |
| `instance_name` | Instance name used for name generation | `string` | No |
| `resource_prefix` | Prefix used for name generation | `string` | No |
| `location` | Azure region. Falls back to `global_config.global.location` | `string` | No |

### Subnet configuration

Each node pool (default and additional) supports two mutually exclusive ways to specify the subnet:

| Field | Description | Default |
|---|---|---|
| `vnet_subnet_name` | Subnet name within the spoke VNet defined in `global_config`. The module constructs the full resource ID automatically. | `aks-snet` |
| `vnet_subnet_id` | Full Azure subnet resource ID. Use this when the subnet lives outside the spoke VNet or when you need explicit control over the ID. | — |

`vnet_subnet_name` takes precedence in the defaults resolution; supply `vnet_subnet_id` directly in `config` to override it completely.

## Outputs

| Name | Description |
|---|---|
| `kubernetes_cluster_id` | The ID of the AKS cluster |
| `kubernetes_cluster_name` | The name of the AKS cluster |
| `kubernetes_cluster_oidc_issuer_url` | The OIDC issuer URL for workload identity federation |
| `kubernetes_cluster_defaults` | The resolved module defaults object |
| `kubernetes_cluster_cluster_identity` | Principal ID and client ID of the cluster control plane managed identity |
| `kubernetes_cluster_kubelet_identity` | Principal ID and client ID of the kubelet managed identity |
| `kubernetes_cluster_certmanager_identity` | Principal ID and client ID of the cert-manager managed identity |
| `kubernetes_cluster_keyvault_identity` | Principal ID and client ID of the Istio ingress gateway Key Vault managed identity |
| `kubernetes_cluster_crossplane_identity` | Principal ID and client ID of the Crossplane managed identity |

## Security defaults

| Setting | Default | Reason |
|---|---|---|
| `private_cluster_enabled` | `true` | No public API server endpoint |
| `local_account_disabled` | `true` | Enforces Azure RBAC authentication only |
| `oidc_issuer_enabled` | `true` | Required for workload identity |
| `workload_identity_enabled` | `true` | Enables federated credential authentication for pods |
| `azure_active_directory_role_based_access_control.azure_rbac_enabled` | `true` | Azure RBAC for Kubernetes authorisation |
| `default_node_pool.node_public_ip_enabled` | `false` | Nodes have no public IP |
| `default_node_pool.only_critical_addons_enabled` | `true` | System pool runs system workloads only |
| `network_profile.network_data_plane` | `cilium` | eBPF-based data plane |
| `network_profile.network_policy` | `cilium` | Cilium network policy enforcement |
| `service_mesh_profile.mode` | `Istio` | Managed Istio service mesh |
| `service_mesh_profile.external_ingress_gateway_enabled` | `false` | No public ingress gateway |
| `key_vault_secrets_provider.secret_rotation_enabled` | `true` | Automatic secret rotation |
| `key_vault_secrets_provider.secret_rotation_interval` | `2m` | Rotation check frequency |
| `automatic_upgrade_channel` | `stable` | Automatic patch upgrades on stable channel |
| `identity.type` | `UserAssigned` | Pre-created identity for predictable RBAC |

## Requirements

| Name | Version |
|---|---|
| Terraform | `>= 1.14.0` |
| hashicorp/azurerm | `~> 4.62.1` |

### Required provider aliases

| Alias | Purpose |
|---|---|
| `azurerm.privatelink_dns` | Looks up the AKS private DNS zone for the cluster identity role assignment |
| `azurerm.public_dns` | Looks up public and shadow-private DNS zones for cert-manager role assignments |
| `azurerm.private_dns` | Writes the wildcard A record for internal load balancer ingress routing |
