
# Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "fastapi-aks-cluster"
  location            = azurerm_resource_group.fastapi_rg.location
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  dns_prefix          = "fastapiaks"

  default_node_pool {
    name                = "default"
    vm_size             = "Standard_DS2_v2"
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id

    #Auto Scaling autoclsuter for nodes
    auto_scaling_enabled = true
    min_count = 2
    max_count = 4

  }

  identity {
    type = "SystemAssigned"
  }



  tags = {
    Environment = "Production"
  }
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    dns_service_ip     = "10.0.2.10"
    service_cidr       = "10.0.2.0/24"
  }
  depends_on = [azurerm_subnet.aks_subnet]
}

# //HPA horizontal pod
resource "kubernetes_horizontal_pod_autoscaler_v2" "myapp_hpa" {
  metadata {
    name      = "my-app-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "my-app"
    }

    min_replicas = 2
    max_replicas = 5

    # CPU-based autoscaling (targets ~50% average CPU utilization)
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}


//VPA
resource "kubernetes_manifest" "myapp_vpa" {
    depends_on = [azurerm_kubernetes_cluster.aks]

  manifest = {
    "apiVersion" = "autoscaling.k8s.io/v1"
    "kind"       = "VerticalPodAutoscaler"
    "metadata" = {
      "name"      = "myapp-vpa"
      "namespace" = "default"
    }
    "spec" = {
      "targetRef" = {
        "apiVersion" = "apps/v1"
        "kind"       = "Deployment"
        "name"       = "my-app"
      }
      "updatePolicy" = {
        "updateMode" = "Auto"
      }
    }
  }
}



# Add  AcrPull on AKS permission
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  skip_service_principal_aad_check = true

}