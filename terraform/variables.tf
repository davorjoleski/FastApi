# Name of the Azure Resource Group
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "myapp-rg"
}

# Azure location/region
variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

# Base name for the Azure Container Registry (must be globally unique when combined with suffix)
variable "acr_name" {
  description = "Base name for Azure Container Registry (globally unique)"
  type        = string
  default     = "myappacr"
}

# Name for the AKS cluster
variable "aks_name" {
  description = "Name of the Azure Kubernetes Service cluster"
  type        = string
  default     = "myapp-aks"
}

# DNS prefix for the AKS cluster (must be unique within Azure)
variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "myappaks"
}

# Number of nodes in the AKS default node pool
variable "node_count" {
  description = "Node count for the AKS default node pool"
  type        = number
  default     = 3
}

# Name of the blob container for uploads
variable "container_name" {
  description = "Name of the Azure Storage blob container for document uploads"
  type        = string
  default     = "intake"
}

# (Optional) Suffix length for unique naming (used with random provider)
variable "suffix_length" {
  description = "Length of random suffix for unique resource names"
  type        = number
  default     = 6
}
