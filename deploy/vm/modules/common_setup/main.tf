# Create a resource group.

resource "null_resource" "configuration-check" {
  provisioner "local-exec" {
    command = "ansible-playbook ../../ansible/configcheck.yml"
  }
}

resource "azurerm_resource_group" "hana-resource-group" {
  depends_on = [null_resource.configuration-check]
  name       = var.az_resource_group
  location   = var.az_region

  tags = {
    environment = "Terraform SAP HANA deployment"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.sap_sid}-vnet"
  location            =  azurerm_resource_group.hana-resource-group.location
  resource_group_name =  azurerm_resource_group.hana-resource-group.name
  address_space       = ["10.0.0.0/21"]
}