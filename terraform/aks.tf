# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
    name                   = "aks-deveops"
    location               = azurerm_resource_group.main.location
    resource_group_name    = azurerm_resource_group.main.name
    dns_prefix             = "aks-deveops"

    default_node_pool {
        name            = "default"
        node_count      = 1
        vm_size         = "Standard_D2s_v5"
    }

    identity {
        type = "SystemAssigned"
    }

    network_profile {
        network_plugin = "azure"
        network_policy = "azure"
    }

    tags = {
        Environment = "Development"
    }
}

# Output kubeconfig
output "kubeconfig" {
    value = azurerm_kubernetes_cluster.main.kube_config_raw
    sensitive = true
}

output "aks_cluster_name" {
    value = azurerm_kubernetes_cluster.main.name
}