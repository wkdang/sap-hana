#######################################################################
# PROVIDER
#######################################################################

provider "azurerm" {
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
}

#######################################################################
# RESOURCES
#######################################################################

# RESOURCE GROUP ======================================================
resource "azurerm_resource_group" "hana_rg" {
  name     = "${local.rg_name}"
  location = "${lookup(local.hana_sites[0], "region")}"
}

# NETWORK SECURITY GROUP ==============================================
resource "azurerm_network_security_group" "hana_nsg" {
  name                = "${local.resource_prefix}nsg-hana"
  location            = "${lookup(local.hana_sites[0], "region")}"
  resource_group_name = "${azurerm_resource_group.hana_rg.name}"
}

# NETWORK SECURITY GROUP RULE: SSH ====================================
resource "azurerm_network_security_rule" "hana_nsg_rule_ssh" {
  name                        = "SSH inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = "${local.allowed_ip_ranges}"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.hana_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.hana_nsg.name}"
  count                       = "${local.hana_enable_public_ip && local.hana_enable_ssh_access ? 1 : 0}"
}

# NETWORK SECURITY GROUP RULE: HDB ====================================
resource "azurerm_network_security_rule" "hana_nsg_rule_hdb" {
  name                        = "HDB inbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3${local.hana_instance_num}00-3${local.hana_instance_num}99"
  source_address_prefixes     = "${local.allowed_ip_ranges}"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.hana_rg.name}"
  network_security_group_name = "${azurerm_network_security_group.hana_nsg.name}"
  count                       = "${local.hana_enable_public_ip && local.hana_enable_hdb_access ? 1 : 0}"
}

#######################################################################
# MODULES
#######################################################################

module "hana_ha" {
  source             = "./hana_ha"
  enabled            = "${local.hana_site_count > 1}"
  resource_prefix    = "${local.resource_prefix}"
  hana_rg_name       = "${azurerm_resource_group.hana_rg.name}"
  hana_region        = "${lookup(local.hana_sites[0], "region")}"
  hana_address_space = "${lookup(local.hana_sites[0], "address_space")}"
  hana_instance_num  = "${local.hana_instance_num}"
}

module "hana_instance_1" {
  source                = "./hana_instance"
  enabled               = true
  resource_prefix       = "${local.resource_prefix}"
  hana_rg_name          = "${azurerm_resource_group.hana_rg.name}"
  hana_sid              = "${local.hana_sid}"
  hana_instance_num     = "${local.hana_instance_num}"
  hana_node_count       = "${local.hana_node_count}"
  hana_vm_sku           = "${local.hana_vm_sku}"
  hana_vm_username      = "${local.hana_vm_username}"
  hana_disk_labels      = "${local.hana_disk_labels}"
  hana_disk_sizes       = "${local.hana_disk_sizes}"
  hana_disk_counts      = "${local.hana_disk_counts}"
  hana_disk_types       = "${local.hana_disk_types}"
  hana_disk_caches      = "${local.hana_disk_caches}"
  hana_vnet_name        = "${module.hana_ha.vnet_name}"
  hana_region           = "${lookup(local.hana_sites[0], "region")}"
  hana_address_space    = "${lookup(local.hana_sites[0], "address_space")}"
  hana_subnet           = "${lookup(local.hana_sites[0], "subnet")}"
  availability_set_id   = "${module.hana_ha.availability_set_id}"
  hana_enable_public_ip = "${local.hana_enable_public_ip}"
  hana_nsg_id           = "${azurerm_network_security_group.hana_nsg.id}"
  hana_instance_name    = "${replace(replace(local.label_instance, "[type]", "db"), "[site]", local.hana_site_count > 1 ? format("-%s", lookup(local.hana_sites[0], "site_name", "")) : "")}"
}

module "hana_instance_2" {
  source                = "./hana_instance"
  enabled               = "${local.hana_site_count >= 2}"
  resource_prefix       = "${local.resource_prefix}"
  hana_rg_name          = "${azurerm_resource_group.hana_rg.name}"
  hana_sid              = "${local.hana_sid}"
  hana_instance_num     = "${local.hana_instance_num}"
  hana_node_count       = "${local.hana_node_count}"
  hana_vm_sku           = "${local.hana_vm_sku}"
  hana_vm_username      = "${local.hana_vm_username}"
  hana_disk_labels      = "${local.hana_disk_labels}"
  hana_disk_sizes       = "${local.hana_disk_sizes}"
  hana_disk_counts      = "${local.hana_disk_counts}"
  hana_disk_types       = "${local.hana_disk_types}"
  hana_disk_caches      = "${local.hana_disk_caches}"
  hana_vnet_name        = "${module.hana_ha.vnet_name}"
  hana_region           = "${lookup(local.hana_sites[1], "region")}"
  hana_address_space    = "${lookup(local.hana_sites[1], "address_space", "")}"
  hana_subnet           = "${lookup(local.hana_sites[1], "subnet")}"
  availability_set_id   = "${module.hana_ha.availability_set_id}"
  hana_enable_public_ip = "${local.hana_enable_public_ip}"
  hana_nsg_id           = "${azurerm_network_security_group.hana_nsg.id}"
  hana_instance_name    = "${replace(replace(local.label_instance, "[type]", "db"), "[site]", local.hana_site_count > 1 ? format("-%s", lookup(local.hana_sites[1], "site_name", "")) : "")}"
}
