output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.main.name
}

output "public_ip_address" {
  description = "IP pública de la VM"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_name" {
  description = "Nombre de la VM"
  value       = azurerm_linux_virtual_machine.main.name
}

output "key_vault_name" {
  description = "Nombre del Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI del Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}