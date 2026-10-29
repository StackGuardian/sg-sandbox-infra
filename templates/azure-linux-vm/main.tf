# A small Ubuntu VM in its own resource group and VNet. The NSG has no inbound
# rules unless allowed_ssh_cidrs is set. Login is by a generated SSH key only.

locals {
  tags = {
    managed-by       = "stackguardian-sandbox"
    sandbox-template = "azure-linux-vm"
  }
  name           = "${var.name_prefix}-${random_string.suffix.result}"
  admin_username = "azureuser"
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = ["10.70.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  name                 = "snet-${local.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.70.1.0/24"]
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags
}

resource "azurerm_network_security_rule" "ssh" {
  count = length(var.allowed_ssh_cidrs) > 0 ? 1 : 0

  name                        = "allow-ssh"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_ssh_cidrs
  destination_address_prefix  = "*"
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  count = var.public_ip_enabled ? 1 : 0

  name                = "pip-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_enabled ? azurerm_public_ip.this[0].id : null
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                  = "vm-${local.name}"
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  size                  = var.vm_size
  admin_username        = local.admin_username
  network_interface_ids = [azurerm_network_interface.this.id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = local.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = local.tags

  # The NSG must be on the subnet before the VM starts.
  depends_on = [azurerm_subnet_network_security_group_association.this]
}
