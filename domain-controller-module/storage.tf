resource "azurerm_managed_disk" "dc_data_disk" {
  count               = 2
  name                 = "${var.resource_group_name}-tf-datadisk${count.index}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size  # Adjust the size of the disk as needed
}

resource "azurerm_virtual_machine_data_disk_attachment" "dc_disk_attach" {
  count               = 2
  managed_disk_id    = azurerm_managed_disk.dc_data_disk[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.dc[count.index].id
  lun                = 0  # Logical Unit Number (LUN) of the disk
  caching            = "None"
}



# Create a storage account
resource "azurerm_storage_account" "sa" {
  name                     = "${var.resource_group_name}-tf-sa"
  location             = var.location
  resource_group_name  = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a blob container
resource "azurerm_storage_container" "sc" {
  name                  = "${var.resource_group_name}-tf-sc"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Upload PowerShell scripts to the blob container
resource "azurerm_storage_blob" "script1" {
  name                   = "test.ps1"
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sc.name
  type                   = "Block"
  source                 = "${path.module}/test.ps1"
}




# # Enable encryption

# data "azurerm_client_config" "current" {}


# resource "azurerm_key_vault" "dc_vault" {
#   name                        = "${var.resource_group_name}-keyvault"
#   location                    = var.location
#   resource_group_name         = var.resource_group_name
#   tenant_id                   = data.azurerm_client_config.current.tenant_id
#   sku_name                    = "premium"
#   enabled_for_disk_encryption = true
#   purge_protection_enabled    = true
# }

# resource "azurerm_key_vault_key" "dc_key" {
#   name         = "${var.resource_group_name}-des-key"
#   key_vault_id = azurerm_key_vault.dc_vault.id
#   key_type     = "RSA"
#   key_size     = 2048

#   depends_on = [
#     azurerm_key_vault_access_policy.example-user
#   ]

#   key_opts = [
#     "decrypt",
#     "encrypt",
#     "sign",
#     "unwrapKey",
#     "verify",
#     "wrapKey",
#   ]
# }

# resource "azurerm_disk_encryption_set" "dc_set" {
#   name                = "des"
#   resource_group_name = var.resource_group_name
#   location            = var.location
#   key_vault_key_id    = azurerm_key_vault_key.dc_key.id

#   identity {
#     type = "SystemAssigned"
#   }
# }


# # Cannot create due to subscription limitation
# resource "azurerm_key_vault_access_policy" "example-disk" {
#   key_vault_id = azurerm_key_vault.dc_vault.id

#   tenant_id = azurerm_disk_encryption_set.dc_set.identity[0].tenant_id
#   object_id = azurerm_disk_encryption_set.dc_set.identity[0].principal_id

#   key_permissions = [
#     "Create",
#     "Delete",
#     "Get",
#     "Purge",
#     "Recover",
#     "Update",
#     "List",
#     "Decrypt",
#     "Sign",
#   ]
# }

# resource "azurerm_key_vault_access_policy" "example-user" {
#   key_vault_id = azurerm_key_vault.dc_vault.id

#   tenant_id = data.azurerm_client_config.current.tenant_id
#   object_id = data.azurerm_client_config.current.object_id

#   key_permissions = [
#     "Create",
#     "Delete",
#     "Get",
#     "Purge",
#     "Recover",
#     "Update",
#     "List",
#     "Decrypt",
#     "Sign",
#     "GetRotationPolicy",
#   ]
# }

# resource "azurerm_role_assignment" "example-disk" {
#   scope                = azurerm_key_vault.dc_vault.id
#   role_definition_name = "Key Vault Crypto Service Encryption User"
#   principal_id         = azurerm_disk_encryption_set.dc_set.identity[0].principal_id
# }


# resource "azurerm_virtual_machine_extension" "dc_encryption" {
#   count                      = 2
#   name                       = "${var.resource_group_name}-tf-vm"
#   virtual_machine_id         = azurerm_windows_virtual_machine.dc[count.index].id
#   publisher                  = "Microsoft.Azure.Security"
#   type                       = "AzureDiskEncryption"
#   type_handler_version       = "2.2"
#   auto_upgrade_minor_version = true

#   settings = <<SETTINGS
#     {
#         "EncryptionOperation": "EnableEncryption",
#         "KeyVaultURL": "${azurerm_key_vault.dc_vault.vault_uri}",
#         "KeyVaultResourceId": "${azurerm_key_vault.dc_vault.id}",
#         "KeyEncryptionKeyURL": "https://${azurerm_key_vault.dc_vault.name}.vault.azure.net/keys/${azurerm_key_vault_key.dc_key.name}/${azurerm_key_vault_key.dc_key.versionless_id}",
#         "KeyEncryptionAlgorithm": "RSA-OAEP",
#         "VolumeType": "All"
#     }
# SETTINGS

#   depends_on = [
#     azurerm_key_vault_access_policy.example-disk,
#     azurerm_role_assignment.example-disk,
#   ]
# }
# #KeyEncryptionKeyUrl to be in format https://<vaultName>.vault.azure.net/keys/<keyName>/<keyVersion> 
# #"KeyEncryptionKeyURL":"https://Candidate-2731-keyvault.vault.azure.net/keys/Candidate-2731-des-key/https://candidate-2731-keyvault.vault.azure.net/keys/Candidate-2731-des-key/3d58c487086a46768e7a4cb2211fd07d",