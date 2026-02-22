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

variable "environment" {
    description   = "Environment (dev/prod)"
    type          = string
    default       = "dev"
}

variable "allowed_ip" {
    description     = "IP permitido para acceso SSH/HTTP"
    type            = string
    default         = "190.84.117.210/32"
}

variable "db_password" {
    description   = "Database password"
    type          = string
    sensitive     = true
    default       = "MySecurePassword123!"
}

variable "api_key" {
    description   = "API Key for external services"
    type          = string
    sensitive     = true
    default       = "sk-1234567890abcdef"
}