terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
     Environment = "Terraform Getting Started"
     Team = "DevOps"
   }
}

resource "azurerm_virtual_network" "vnet" {
    name                = "annanTFVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.resource_group_location
    resource_group_name = azurerm_resource_group.rg.name
} 

resource "azurerm_subnet" "sub" {
  name                 = "annansubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "annanpublicip" {
    name                         = "annanPublicIP"
    location                     = var.resource_group_location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"

}
# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = var.resource_group_location
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

resource "azurerm_network_interface" "nic" {
  name                = "annannic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.annanpublicip.id
  }
}


resource "azurerm_virtual_machine" "vm" {

  name                  = "vm"

  location              = var.resource_group_location

  resource_group_name   = azurerm_resource_group.rg.name

  network_interface_ids = [azurerm_network_interface.nic.id]

  vm_size               = "Standard_D2_v2"



  storage_image_reference {

    publisher = "Canonical"

    offer     = "UbuntuServer"

    sku       = "16.04-LTS"

    version   = "latest"

  }



  storage_os_disk {

    name              = "osdisk"

    caching           = "ReadWrite"

    create_option     = "FromImage"

    managed_disk_type = "Standard_LRS"

  }



  os_profile {

    computer_name  = "hostname"

    admin_username = var.user

    admin_password = var.password

  }



  os_profile_linux_config {

    disable_password_authentication = false

  }

}



resource "azurerm_virtual_machine_extension" "vme" {

  virtual_machine_id         = azurerm_virtual_machine.vm.id

  name                       = "vme"

  publisher                  = "Microsoft.Azure.Extensions"

  type                       = "CustomScript"

  type_handler_version       = "2.0"

  auto_upgrade_minor_version = true



  settings = <<SETTINGS

  {

  "commandToExecute": "sudo apt-get update && apt-get install -y apache2 && echo 'hello world' > /var/www/html/index.html"

  }

  SETTINGS

}

