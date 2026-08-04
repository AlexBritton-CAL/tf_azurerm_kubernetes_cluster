# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Terraform module for provisioning Azure Kubernetes Service (AKS) clusters. It is designed to be consumed as a reusable module by other Terraform configurations, not run standalone. The module creates a fully-configured private AKS cluster with associated managed identities, RBAC, networking, and optional add-ons.

## Common Terraform Commands

```bash
# Initialise working directory (run from root or from a consuming config)
terraform init

# Validate configuration syntax and internal consistency
terraform validate

# Format all .tf files
terraform fmt -recursive

# Plan changes (requires a consuming configuration with vars set)
terraform plan

# Apply changes
terraform apply
```

## Architecture

### Configuration Pattern

The module uses a two-layer configuration system throughout:

1. **`var.config`** – caller-supplied config object (type `any`), passed from the consuming layer, this is usually passed to the root module from a yaml file called config.yaml
2. **`local.module_defaults`** – opinionated defaults defined in `module_defaults.tf`

Values are resolved with `coalesce(try(var.config.<attr>, null), local.module_defaults.<attr>)`, meaning `var.config` takes precedence but defaults are always available. This pattern is used consistently across all attributes in `main.tf`.

### File Layout

| File | Purpose |
|---|---|
| `main.tf` | `azurerm_kubernetes_cluster`, `azurerm_private_link_service`, `azurerm_private_dns_a_record`, and the `cluster_node_pool` module calls |
| `module_defaults.tf` | Opinionated defaults for every cluster attribute, vnet subnet ID helpers |
| `variables.tf` | All input variables; top-level vars act as fallbacks when `var.config` isn't used |
| `versions.tf` | Provider version pins (`azurerm ~> 4.81.0`, Terraform `>= 1.1.0`) |
| `identity_cluster.tf` | `cluster_identity` and `kubelet_identity` user-assigned managed identities, plus role assignments (Managed Identity Operator, Contributor on VNet, Private DNS Zone Contributor) |
| `identity_cert_manager.tf` | Managed identity + federated credential for cert-manager workload identity; DNS Zone Contributor role assignments for public and shadow-private DNS zones |
| `identity_keyvaut.tf` | Managed identity + federated credential for the Istio ingress gateway to read Key Vault certificates; Key Vault Certificate User role assignment |
| `rbac_container_registry.tf` | Optional ACR pull role assignment for kubelet identity (enabled when `container_registry.name` is set) |
| `outputs.tf` | Exports `cluster_name`, `oidc_issuer_url`, and the resolved `kubernetes_cluster` defaults |

### Sub-module: `modules/cluster_node_pool`

Wraps `azurerm_kubernetes_cluster_node_pool`. Instantiated via `for_each` over `var.config.node_pools`. Uses the same defaults-then-config merge pattern via its own `module_defaults.tf`. `node_count` is ignored in lifecycle to allow autoscaler to manage it.

### Provider Aliases

Three provider aliases are required by the consuming configuration:
- `azurerm.privatelink_dns` – used to look up the AKS private DNS zone
- `azurerm.public_dns` – used to look up public and shadow-private DNS zones for cert-manager
- `azurerm.private_dns` – used to write the wildcard A record for the internal load balancer

### Key Defaults (from `module_defaults.tf`)

- **Network**: Azure CNI overlay, Cilium data plane + policy, service CIDR `10.0.11.0/24`, pod CIDR `10.244.0.0/16`
- **Service mesh**: Istio (`asm-1-27`) with internal ingress gateway enabled
- **Cluster identity**: `UserAssigned`
- **Default node pool**: `Standard_B4s_v2`, autoscaling 2–5, system-only (`only_critical_addons_enabled = true`), across zones 1/2/3
- **Additional node pools**: `Standard_B4ms`, autoscaling 1–4, max 50 pods, across zones 1/2/3
- **Maintenance windows**: Weekly on Saturday (upgrades) and Sunday (node OS) at 02:00 UTC
- **Workload autoscaler**: KEDA and VPA both enabled
- **Key Vault secrets provider**: enabled with 2-minute rotation interval

### Naming Convention

Cluster name is generated as `{resource_prefix}-{instance_name}-aks` when `var.config.generate_name` is true. Identity resources follow `{cluster_name}-clusterid`, `{cluster_name}-kubeletid`, etc.
