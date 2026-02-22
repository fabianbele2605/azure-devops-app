# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-devops-fb-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Access Policy para el usuario actual
resource "azurerm_key_vault_access_policy" "user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover"
  ]
}

# Access Policy para la VM (Managed Identity)
resource "azurerm_key_vault_access_policy" "vm" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_virtual_machine.main.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Secrets de ejemplo
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.user]
}

resource "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  value        = var.api_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault_access_policy.user]
}

# Data source para obtener configuración actual
data "azurerm_client_config" "current" {}
