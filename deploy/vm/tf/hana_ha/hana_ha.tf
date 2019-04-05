#######################################################################
# VARIABLES
#######################################################################

variable "enabled" {}
variable "resource_prefix" {}
variable "hana_rg_name" {}
variable "hana_instance_num" {}
variable "hana_region" {}
variable "hana_address_space" {}

#######################################################################
# RESOURCES
#######################################################################

# VNET ================================================================
resource "azurerm_virtual_network" "hana_vnet" {
  name                = "${var.resource_prefix}vnet"
  count               = "${var.enabled ? 1 : 0}"
  location            = "${var.hana_region}"
  resource_group_name = "${var.hana_rg_name}"
  address_space       = ["${var.hana_address_space}"]
}

# AVAILABILITY SET ====================================================
resource "azurerm_availability_set" "hana_availability_set" {
  name                         = "${var.resource_prefix}availabilityset"
  count                        = "${var.enabled ? 1 : 0}"
  location                     = "${var.hana_region}"
  resource_group_name          = "${var.hana_rg_name}"
  platform_fault_domain_count  = "2"
  platform_update_domain_count = "20"
  managed                      = true
}
