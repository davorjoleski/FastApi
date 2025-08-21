provider "azurerm" {
  features {}


  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id


}

# Random suffix to avoid name conflicts
resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}
# Resource Group
resource "azurerm_resource_group" "fastapi_rg" {
  name     = "fastapi-rg"
  location = "West Europe"
}

# Virtual Network
resource "azurerm_virtual_network" "fastapi_vnet" {
  name                = "fastapi-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.fastapi_rg.location
  resource_group_name = azurerm_resource_group.fastapi_rg.name
}

# Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.fastapi_rg.name
  virtual_network_name = azurerm_virtual_network.fastapi_vnet.name
  address_prefixes     = ["10.0.1.0/24"]


}

# Storage Account
resource "azurerm_storage_account" "fastapistorageacct" {
  name                     = "fastapistorageacct"
  resource_group_name      = azurerm_resource_group.fastapi_rg.name
  location                 = azurerm_resource_group.fastapi_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Blob Container
resource "azurerm_storage_container" "intake" {
  name                  = "intake"
  storage_account_id    = azurerm_storage_account.fastapistorageacct.id
  container_access_type = "private"
}
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.fastapistorageacct.id
  container_access_type = "private"
}
# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "fasttapiacr69418"
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  location            = azurerm_resource_group.fastapi_rg.location
  sku                 = "Basic"

 admin_enabled = true
  tags = {
    owner       = "terraform"
    environment = "dev"
  }
}

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



# Add  AcrPull на AKS
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  skip_service_principal_aad_check = true

}

#provider for creatigins k8s resoruces screts deployments services from terrafrom
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_deployment" "myapp" {
  metadata {
    name = "my-app"   # ова е името на deployment-от
    labels = {
      app = "my-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
      }

      spec {
        container {
          name  = "my-app"
          image = "nginx:latest"

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "myapp_hpa" {
  metadata {
    name = "my-app-hpa"
  }

  spec {
    max_replicas = 3
    min_replicas = 1

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.myapp.metadata[0].name
      # ако ти прави unresolved reference, едноставно замени со директен string:
      # name = "my-app"
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type               = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}




#for imagepullsecrets  for pods pull images
resource "kubernetes_secret" "acr_secret" {
  metadata {
    name      = "acr-secret"
    namespace = "default"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${azurerm_container_registry.acr.login_server}" = {
          username = azurerm_container_registry.acr.admin_username
          password = azurerm_container_registry.acr.admin_password
          email    = "example@intertec.io"
        }
      }
    })
  }
}

##########################################################
# Secret за Azure Storage Connection String
##########################################################
resource "kubernetes_secret" "azure_storage_secret" {
  metadata {
    name      = "azure-connection-secret"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    connectionString = azurerm_storage_account.fastapistorageacct.primary_connection_string
  }
}
