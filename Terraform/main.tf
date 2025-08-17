terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "East US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group and rule for SSH
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate Network Security Group to the subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "publicip" {
  name                = "${var.vm_name}-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "East US"
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_network_interface" "nic" {
  name                = "Nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  disable_password_authentication = true
  
  network_interface_ids = [azurerm_network_interface.nic.id]
  
  admin_ssh_key {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDK2vlyVQybOWnpBr68m3z6zb1zl8S5BKsN+VQkkwrm9EeamV0h178S39zAOcco68zFFpZdN0nDtsmrtI3xhOiBt+v3xoEVfAafD8k2BYovmSa8ZwasmdvVI68F9y+U6Kkxow0huMOgo+Xcx2hSF4sSZuDZ/yhUuKgluZhSnCMLY6OhlIwBIDpHZkk704WcmgL2Rf5fRkMXpAaQTyJycguZdle24zvAFx7EVPp1Rm77RdTyV5us/UtJOibUfnD4Uv7/p+ZHPsZ2aee+0U2yNfBN8PZbTbPRWB1sLB00Ob3cMS6oo3bk/10bXg+xJqcjvnmJbXaEWNvXCTDORgmcrnZNT+Y5Qhu4ToFA1g37Lqg8CM0CmaA6GGsGZ/pk/d4qMNcAO9K0kCQTOoXZqp0j8+7KQRytUjo6Vavj22JHZrmuHs4CJj1UqhmSGx+uJKqyObhwmrcKvODghacJLavpi9STUljzZyNeCsspyiH2OqMh6ePlvyshoQYjyM7aKy224s= e8s@DESKTOP-058F89L"
  }
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}