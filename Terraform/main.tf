terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.112.0"
    }
  }
}


locals {
  resource_group_name="tfe-rg"
  location="West India"
  virtual_network={
    name="tfe-vnet"
    address_space="10.0.0.0/16"
  }

  subnets=[
    {
      name="subnetA"
      address_prefix="10.0.0.0/24"
    },
    {
      name="subnetB"
      address_prefix="10.0.1.0/24"
    }
  ]
}

resource "azurerm_resource_group" "tfe-rg" {
  name     = local.resource_group_name
  location = local.location  
}

resource "azurerm_virtual_network" "tfe-vnet" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = [local.virtual_network.address_space]  

  subnet {
    name           = local.subnets[0].name
    address_prefix = local.subnets[0].address_prefix
  }

  subnet {
    name           = local.subnets[1].name
    address_prefix = local.subnets[1].address_prefix
  }
   depends_on = [
     azurerm_resource_group.tfe-rg
   ]
  }
resource "azurerm_storage_account" "tfesa" {
  name                     = "tfesaaks"
  resource_group_name      = azurerm_resource_group.tfe-rg.name
  location                 = azurerm_resource_group.tfe-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind			   = "StorageV2"

  tags = {
    environment = "staging"
  }
}
resource "azurerm_virtual_machine" "importvm" {
  name                  = "importvm"
  location              = "southindia"
  resource_group_name   = azurerm_resource_group.tfe-rg.name
  network_interface_ids = ["/subscriptions/3653818b-13b8-49d6-b967-9d70ddfd7b5e/resourceGroups/tfe-rg/providers/Microsoft.Network/networkInterfaces/importvm652"]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "importvm_OsDisk_1_1fcbad0e3927460d8cef6fdc8c313678"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    managed_disk_id   = "/subscriptions/3653818b-13b8-49d6-b967-9d70ddfd7b5e/resourceGroups/tfe-rg/providers/Microsoft.Compute/disks/importvm_OsDisk_1_1fcbad0e3927460d8cef6fdc8c313678"
    disk_size_gb      = 127
  }

  os_profile {
    computer_name  = "importvm"
    admin_username = "import"
    # Note: Do not include the admin_password in the Terraform config for security reasons.
  }

  os_profile_windows_config {
    provision_vm_agent            = true
    enable_automatic_upgrades     = true
  }
}
