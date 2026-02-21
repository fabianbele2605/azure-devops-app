variable "resource_group_name" {
    description = "Nombre del Resource Group"
    type        = string
    default     = "rg-terraform-demo"
}

variable "location" {
    description   = "Región de Azure"
    type          = string
    default       = "westus2"
}

variable "vm_size" {
    description   = "Tamaño de la VM"
    type          = string
    default       = "Standard_D2s_v5"
}

variable "admin_username" {
    description   = "Usuario admin de la VM"
    type          = string
    default       = "azureuser"
}