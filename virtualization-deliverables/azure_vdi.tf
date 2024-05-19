# Define Azure provider
provider "azurerm" {
  features {}
}

# Create Azure Virtual Desktop resource group
resource "azurerm_resource_group" "avd_rg" {
  name     = "avd-resource-group"
  location = "East US" # Change as per your region
}

# Create Azure Virtual Desktop workspace
resource "azurerm_virtual_desktop_workspace" "avd_workspace" {
  name                = "avd-workspace"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
}

# Create Azure Virtual Desktop host pool
resource "azurerm_virtual_desktop_host_pool" "avd_host_pool" {
  name                = "avd-host-pool"
  location            = azurerm_resource_group.avd_rg.location
  resource_group_name = azurerm_resource_group.avd_rg.name
  workspace_id        = azurerm_virtual_desktop_workspace.avd_workspace.id
  friendly_name       = "AVD Host Pool"
  description         = "Azure Virtual Desktop Host Pool"

  type = "Pooled"

  # Specify custom settings for the host pool
  custom_rdp_property {
    name  = "audiocapturemode"
    value = "0"
  }

  # Define the VM template for the host pool
  vm_template {
    image_type = "Gallery"
    gallery_image_id = "/subscriptions/<subscription_id>/resourceGroups/<resource_group_name>/providers/Microsoft.Compute/galleries/Windows-10-Edition-Multisession/versions/latest"
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "19h2-evd"
  }

  # Define the application group
  application_group {
    name            = "AVD-App-Group"
    resource_scope  = azurerm_virtual_desktop_workspace.avd_workspace.id
    host_pool_id    = azurerm_virtual_desktop_host_pool.avd_host_pool.id
    friendly_name   = "AVD Application Group"
    description     = "Azure Virtual Desktop Application Group"
    validation_env  = "true"

    # Define application group type as Desktop
    type = "Desktop"

    # Define workspace settings
    workspace_settings {
      allow_new_session = "true"
      use_local_wan     = "false"
      load_balancer_type = "DepthFirst"
    }
  }

  # Specify session host configurations
  vm_disk {
    os_type        = "Windows"
    storage_account_type = "StandardSSD_LRS"
    image_size_gb  = 128
  }

  # Specify scaling configurations
  scaling {
    minimum_capacity = 2
    maximum_capacity = 10
    default_capacity = 2
  }
}

# Join session hosts to Active Directory domain
resource "azurerm_virtual_desktop_host_pool_aad_join" "avd_aad_join" {
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd_host_pool.id
  resource_group_name = azurerm_resource_group.avd_rg.name
  tenant_id           = var.tenant_id # Replace with your Azure AD tenant ID
  domain_join_user    = var.domain_join_user # Replace with a user with permissions to join machines to the domain
  domain_join_password = var.domain_join_password # Replace with the password for the domain join user
}
