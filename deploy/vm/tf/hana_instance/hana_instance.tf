#######################################################################
# VARIABLES
#######################################################################

variable "enabled" {}
variable "resource_prefix" {}
variable "hana_rg_name" {}
variable "hana_sid" {}
variable "hana_instance_num" {}
variable "hana_node_count" {}
variable "hana_vm_sku" {}
variable "hana_vm_username" {}

variable "hana_disk_sizes" {
  type = "list"
}

variable "hana_disk_labels" {
  type = "list"
}

variable "hana_disk_counts" {
  type = "list"
}

variable "hana_disk_types" {
  type = "list"
}

variable "hana_disk_caches" {
  type = "list"
}

variable "hana_address_space" {}
variable "hana_region" {}
variable "hana_subnet" {}
variable "hana_enable_public_ip" {}
variable "hana_nsg_id" {}
variable "hana_instance_name" {}
variable "availability_set_id" {}
variable "hana_vnet_name" {}

#######################################################################
# RESOURCES
#######################################################################

# VNET ================================================================
resource "azurerm_virtual_network" "hana_vnet" {
  name                = "${format("%s-vnet", replace(var.hana_instance_name, "[num]", ""))}"
  count               = "${var.enabled && var.hana_vnet_name == "" ? 1 : 0}"
  location            = "${var.hana_region}"
  resource_group_name = "${var.hana_rg_name}"
  address_space       = ["${var.hana_address_space}"]
}

locals {
  hana_vnet_name = "${var.hana_vnet_name != "" ? var.hana_vnet_name : join(",",azurerm_virtual_network.hana_vnet.*.name) }"
}

# SUBNET ==============================================================
resource "azurerm_subnet" "hana_subnet" {
  name                      = "${format("%s-subnet", replace(var.hana_instance_name, "[num]", ""))}"
  count                     = "${var.enabled ? 1 : 0}"
  resource_group_name       = "${var.hana_rg_name}"
  virtual_network_name      = "${local.hana_vnet_name}"
  address_prefix            = "${var.hana_subnet}"
  network_security_group_id = "${var.hana_nsg_id}"
}

# PUBLIC IPs ==========================================================
resource "azurerm_public_ip" "hana_pips" {
  name                         = "${replace(var.hana_instance_name, "[num]", count.index)}-pip"
  count                        = "${var.enabled && var.hana_enable_public_ip ? var.hana_node_count : 0}"
  location                     = "${var.hana_region}"
  resource_group_name          = "${var.hana_rg_name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${replace(var.hana_instance_name, "[num]", count.index)}"
}

# NETWORK INTERFACEs ==================================================
resource "azurerm_network_interface" "hana_nics_with_pip" {
  name                      = "${replace(var.hana_instance_name, "[num]", count.index)}-nic"
  count                     = "${var.enabled && var.hana_enable_public_ip ? var.hana_node_count : 0}"
  location                  = "${var.hana_region}"
  resource_group_name       = "${var.hana_rg_name}"
  network_security_group_id = "${var.hana_nsg_id}"

  ip_configuration {
    name                          = "${replace(var.hana_instance_name, "[num]", count.index)}-ip"
    subnet_id                     = "${azurerm_subnet.hana_subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.hana_subnet.address_prefix, 4+count.index)}"
    public_ip_address_id          = "${azurerm_public_ip.hana_pips.*.id[count.index]}"
  }
}

resource "azurerm_network_interface" "hana_nics_without_pip" {
  name                      = "${replace(var.hana_instance_name, "[num]", count.index)}-nic"
  count                     = "${var.enabled && !var.hana_enable_public_ip ? var.hana_node_count : 0}"
  location                  = "${var.hana_region}"
  resource_group_name       = "${var.hana_rg_name}"
  network_security_group_id = "${var.hana_nsg_id}"

  ip_configuration {
    name                          = "${replace(var.hana_instance_name, "[num]", count.index)}-ip"
    subnet_id                     = "${azurerm_subnet.hana_subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.hana_subnet.address_prefix, 4+count.index)}"
  }
}

locals {
  hana_nic_id_list = "${var.hana_enable_public_ip ? join(",",azurerm_network_interface.hana_nics_with_pip.*.id) : join(",",azurerm_network_interface.hana_nics_without_pip.*.id)}"
  hana_nic_ids     = "${split(",", local.hana_nic_id_list)}"
}

# DISKs ===============================================================
# -------+---+---+---+---+---+
# VM #   | DATA  |  LOG  | S |
# Disk # | 0 | 1 | 0 | 1 | 0 |
# -------+---+---+---+---+---+
# Count  | 0 | 1 | 2 | 3 | 4 | VM 0
#        | 5 | 6 | 7 | 8 | 9 | VM 1
# -------+---+---+---+---+---+

locals {
  disk_count_per_vm = "${(var.hana_disk_counts[1] + var.hana_disk_counts[2] + var.hana_disk_counts[3])}"
  int_to_str        = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
}

# Spaghetti code compliments of HCL
resource "azurerm_managed_disk" "hana_disks" {
  name                 = "${replace(var.hana_instance_name, "[num]", count.index / local.disk_count_per_vm)}-disk-${var.hana_disk_labels[ (count.index % local.disk_count_per_vm) < var.hana_disk_counts[1] ? 1 : ((count.index % local.disk_count_per_vm) >= (var.hana_disk_counts[1] + var.hana_disk_counts[2]) ? 3 : 2 )]}${var.hana_disk_counts[(count.index % local.disk_count_per_vm) < var.hana_disk_counts[1] ? 1 : ((count.index % local.disk_count_per_vm) >= (var.hana_disk_counts[1] + var.hana_disk_counts[2]) ? 3 : 2 )] == 1 ? "" : local.int_to_str[count.index % local.disk_count_per_vm < var.hana_disk_counts[1] ? count.index % local.disk_count_per_vm : (count.index % local.disk_count_per_vm >= (var.hana_disk_counts[1] + var.hana_disk_counts[2]) ? (count.index % local.disk_count_per_vm) - var.hana_disk_counts[2] - var.hana_disk_counts[1] : (count.index % local.disk_count_per_vm) - var.hana_disk_counts[1])]}"
  count                = "${var.enabled ? local.disk_count_per_vm * var.hana_node_count : 0}"
  location             = "${var.hana_region}"
  resource_group_name  = "${var.hana_rg_name}"
  storage_account_type = "${var.hana_disk_types[(count.index % local.disk_count_per_vm) < var.hana_disk_counts[1] ? 1 : ((count.index % local.disk_count_per_vm) >= (var.hana_disk_counts[1] + var.hana_disk_counts[2]) ? 3 : 2 )]}"
  create_option        = "Empty"
  disk_size_gb         = "${var.hana_disk_sizes[(count.index % local.disk_count_per_vm) < var.hana_disk_counts[1] ? 1 : ((count.index % local.disk_count_per_vm) >= (var.hana_disk_counts[1] + var.hana_disk_counts[2]) ? 3 : 2 )]}"
}

# DISK ATTACHMENTs ====================================================
resource "azurerm_virtual_machine_data_disk_attachment" "hana_disk_to_vm_attachments" {
  count              = "${var.enabled ? local.disk_count_per_vm * var.hana_node_count : 0}"
  managed_disk_id    = "${azurerm_managed_disk.hana_disks.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.hana_vms.*.id[count.index / local.disk_count_per_vm]}"
  lun                = "${1 + (count.index % local.disk_count_per_vm)}"
  caching            = "${var.hana_disk_caches[(count.index % local.disk_count_per_vm) < var.hana_disk_counts[1] ? 1 : ((count.index % local.disk_count_per_vm) >= (var.hana_disk_counts[1] + var.hana_disk_counts[2]) ? 3 : 2 )]}"
}

# VIRTUAL MACHINEs ====================================================
resource "azurerm_virtual_machine" "hana_vms" {
  name                  = "${replace(var.hana_instance_name, "[num]", count.index)}"
  count                 = "${var.enabled ? var.hana_node_count : 0}"
  location              = "${var.hana_region}"
  resource_group_name   = "${var.hana_rg_name}"
  vm_size               = "${var.hana_vm_sku}"
  network_interface_ids = ["${local.hana_nic_ids[count.index]}"]
  availability_set_id   = "${var.availability_set_id}"

  storage_os_disk {
    name              = "${replace(var.hana_instance_name, "[num]", count.index)}-disk-os"
    create_option     = "FromImage"
    disk_size_gb      = "${var.hana_disk_sizes[0]}"
    managed_disk_type = "${var.hana_disk_types[0]}"
    caching           = "${var.hana_disk_caches[0]}"
  }

  storage_image_reference {
    publisher = "SUSE"
    offer     = "SLES-SAP"
    sku       = "12-SP3"
    version   = "latest"
  }

  os_profile {
    computer_name  = "${replace(var.hana_instance_name, "[num]", count.index)}"
    admin_username = "${var.hana_vm_username}"
    admin_password = "Passw0rd1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    # ssh_keys {
    #   path     = "/home/${var.vm_user}/.ssh/authorized_keys"
    #   key_data = "${file("${var.sshkey_path_public}")}"
    # }  	
  }
}
