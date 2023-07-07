terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.0.1"
    }
  }
}

# 2. Configure the AzureRM Provider
provider "azurerm" {
  features {}
  subscription_id = "11e07d93-b7de-44c1-b006-7218b5fb3180"
  client_id       = "b30bfd9a-8e64-4c5a-ac79-c166d9ae713c"
  client_secret   = "mit8Q~qmWXTwifGCRrGggw0m97aJnXNLHwVdTaaZ"
  tenant_id       = "30bf9f37-d550-4878-9494-1041656caf27"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.rgname}"
  location = "${var.rglocation}"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.prefix}-10"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space       = ["${var.vnet_cidr_prefix}"]
}
resource "azurerm_subnet" "sub1" {
  name                 = "sub1"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  address_prefixes     = ["${var.sub1_cidr_prefix}"]
}

resource "azurerm_network_security_group" "nsg1" {
    name               = "${var.prefix}-nsg1"
    location            = "${azurerm_resource_group.rg.location}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
}
resource "azurerm_network_security_rule" "rdp" {
    name = "rdp"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    network_security_group_name = "${azurerm_network_security_group.nsg1.name}"
    priority = 102
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "3389"
    source_address_prefix = "*"
    destination_address_prefix = "*"
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc" {
    subnet_id = azurerm_subnet.sub1.id
    network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_interface" "nic1" {
    name = "${var.prefix}-nic"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location

    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.sub1.id
      private_ip_address_allocation = "Dynamic"
    }

}

resource "azurerm_windows_virtual_machine" "vm002" {
    name = "${var.prefix}-vm002"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    size = "Standard_B1s"
    admin_username = "vm002"
    admin_password = "Vmlinux@1234"
    network_interface_ids = [ azurerm_network_interface.nic1.id ]

    source_image_reference {
      publisher = "MicrosoftWindowsServer"
      offer = "WindowsServer"
      sku = "2012-R2-Datacenter"
      version = "latest"
    }  
    os_disk {
      storage_account_type = "Standard_LRS"
      caching = "ReadWrite"
    }
}