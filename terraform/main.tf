# Resource Group
resource "azurerm_resource_group" "main" {
    name          = var.resource_group_name
    location      = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
    name                = "vnet-terraform"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name
}

# Subnet
resource "azurerm_subnet" "main" {
    name                   = "subnet-principal"
    resource_group_name    = azurerm_resource_group.main.name
    virtual_network_name   = azurerm_virtual_network.main.name
    address_prefixes       = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "main" {
    name                  = "ip-publica-terraform"
    location              = azurerm_resource_group.main.location
    resource_group_name   = azurerm_resource_group.main.name
    allocation_method     = "Static"
    sku                   = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
    name                    = "nsg-terraform"
    location                = azurerm_resource_group.main.location
    resource_group_name     = azurerm_resource_group.main.name

    security_rule {
        name                         = "SSH"
        priority                     = 1000
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "22"
        source_address_prefix        = var.allowed_ip
        destination_address_prefix   = "*"
    }

    security_rule {
        name                        = "HTTP"
        priority                    = 1001
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "80"
        source_address_prefix       = var.allowed_ip
        destination_address_prefix  = "*"

    }

    security_rule {
        name                        = "App"
        priority                    = 1002
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "5000"
        source_address_prefix       = var.allowed_ip
        destination_address_prefix  = "*"
    }

    security_rule {
        name                        = "AllowK8sApp"
        priority                    = 1003
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "30080"
        source_address_prefix       = var.allowed_ip
        destination_address_prefix  = "*"
    }

    security_rule {
        name                        = "AllowGrafana"
        priority                    = 1004
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "30030"
        source_address_prefix       = var.allowed_ip
        destination_address_prefix  = "*"
    }

    security_rule {
        name                        = "AllowPrometheus"
        priority                    = 1005
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "Tcp"
        source_port_range           = "*"
        destination_port_range      = "30090"
        source_address_prefix       = var.allowed_ip
        destination_address_prefix  = "*"
    }
}

# Network Interface
resource "azurerm_network_interface" "main" {
    name                            = "nic-terraform"
    location                        = azurerm_resource_group.main.location
    resource_group_name             = azurerm_resource_group.main.name

    ip_configuration {
        name                            = "ipconfig1"
        subnet_id                       = azurerm_subnet.main.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.main.id
    }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "main" {
    network_interface_id            = azurerm_network_interface.main.id
    network_security_group_id       = azurerm_network_security_group.main.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
    name                    = "vm-terraform"
    resource_group_name     = azurerm_resource_group.main.name
    location                = azurerm_resource_group.main.location
    size                    = var.vm_size
    admin_username          = var.admin_username
    network_interface_ids     = [
        azurerm_network_interface.main.id
    ]

    # Managed Identity para acceder a Key Vault
    identity {
        type = "SystemAssigned"
    }

    admin_ssh_key {
        username       = var.admin_username
        public_key       = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        caching                   = "ReadWrite"
        storage_account_type      = "Standard_LRS"
    }

    source_image_reference {
        publisher    = "Canonical"
        offer        = "0001-com-ubuntu-server-jammy"
        sku          = "22_04-lts-gen2"
        version      = "latest"
    }
}