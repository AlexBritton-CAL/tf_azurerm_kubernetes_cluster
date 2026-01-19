output "zones" {
  value     = azurerm_kubernetes_cluster_node_pool.this.zones
  sensitive = true
}