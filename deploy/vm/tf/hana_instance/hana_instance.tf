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

variable "hana_disk_sizes_data" {
  type = "list"
}

variable "hana_disk_sizes_log" {
  type = "list"
}

variable "hana_disk_sizes_shared" {
  type = "list"
}

variable "hana_address_space" {}
variable "hana_region" {}
variable "hana_subnet" {}
variable "hana_enable_public_ip" {}
variable "hana_nsg_id" {}
variable "hana_instance_name" {}

#######################################################################
# RESOURCES
#######################################################################

# VNET ================================================================
resource "azurerm_virtual_network" "hana_vnet" {
  name                = "${var.resource_prefix}vnet"
  location            = "${var.hana_region}"
  resource_group_name = "${var.hana_rg_name}"
  address_space       = ["${var.hana_address_space}"]
}

# SUBNET ==============================================================
resource "azurerm_subnet" "hana_subnet" {
  name                      = "${var.resource_prefix}${substr(var.hana_subnet, 0, length(var.hana_subnet)-3)}-subnet"
  resource_group_name       = "${var.hana_rg_name}"
  virtual_network_name      = "${azurerm_virtual_network.hana_vnet.name}"
  address_prefix            = "${var.hana_subnet}"
  network_security_group_id = "${var.hana_nsg_id}"
}

# PUBLIC IPs ==========================================================
resource "azurerm_public_ip" "hana_pips" {
  name                         = "${replace(var.hana_instance_name, "[num]", count.index)}-pip"
  count                        = "${var.hana_enable_public_ip ? var.hana_node_count : 0}"
  location                     = "${var.hana_region}"
  resource_group_name          = "${var.hana_rg_name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${replace(var.hana_instance_name, "[num]", count.index)}"
}

# NETWORK INTERFACEs ==================================================
resource "azurerm_network_interface" "hana_nics_with_pip" {
  name                      = "${replace(var.hana_instance_name, "[num]", count.index)}-nic"
  count                     = "${var.hana_enable_public_ip ? var.hana_node_count : 0}"
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
  count                     = "${!var.hana_enable_public_ip ? var.hana_node_count : 0}"
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
# -------+---+---+---+---+---+---+
# VM #   | 0 | 0 | 1 | 1 | 2 | 2 | hana_node_count = 3
# Disk # | 0 | 1 | 0 | 1 | 0 | 1 | length(hana_disk_sizes) = 2
# -------+---+---+---+---+---+---+
# Count  | 0 | 1 | 2 | 3 | 4 | 5 |
# -------+---+---+---+---+---+---+
resource "azurerm_managed_disk" "hana_disks_data" {
  name                 = "${replace(var.hana_instance_name, "[num]", count.index / length(var.hana_disk_sizes_data))}-disk-data${count.index % length(var.hana_disk_sizes_data)}"
  count                = "${var.hana_node_count * length(var.hana_disk_sizes_data)}"
  location             = "${var.hana_region}"
  resource_group_name  = "${var.hana_rg_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${element(var.hana_disk_sizes_data, count.index % length(var.hana_disk_sizes_data))}"
}

resource "azurerm_managed_disk" "hana_disks_log" {
  name                 = "${replace(var.hana_instance_name, "[num]", count.index / length(var.hana_disk_sizes_log))}-disk-log${count.index % length(var.hana_disk_sizes_log)}"
  count                = "${var.hana_node_count * length(var.hana_disk_sizes_log)}"
  location             = "${var.hana_region}"
  resource_group_name  = "${var.hana_rg_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${element(var.hana_disk_sizes_log, count.index % length(var.hana_disk_sizes_log))}"
}

resource "azurerm_managed_disk" "hana_disks_shared" {
  name                 = "${replace(var.hana_instance_name, "[num]", count.index / length(var.hana_disk_sizes_shared))}-disk-shared${count.index % length(var.hana_disk_sizes_shared)}"
  count                = "${var.hana_node_count * length(var.hana_disk_sizes_shared)}"
  location             = "${var.hana_region}"
  resource_group_name  = "${var.hana_rg_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${element(var.hana_disk_sizes_shared, count.index % length(var.hana_disk_sizes_shared))}"
}

# DISK ATTACHMENTs ====================================================
resource "azurerm_virtual_machine_data_disk_attachment" "hana_disk_data_to_vm_attachments" {
  count              = "${var.hana_node_count * length(var.hana_disk_sizes_data)}"
  managed_disk_id    = "${azurerm_managed_disk.hana_disks_data.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.hana_vms.*.id[count.index / length(var.hana_disk_sizes_data)]}"
  lun                = "${1 + (count.index % length(var.hana_disk_sizes_data))}"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "hana_disk_log_to_vm_attachments" {
  count              = "${var.hana_node_count * length(var.hana_disk_sizes_log)}"
  managed_disk_id    = "${azurerm_managed_disk.hana_disks_log.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.hana_vms.*.id[count.index / length(var.hana_disk_sizes_log)]}"
  lun                = "${1 + length(var.hana_disk_sizes_data) + (count.index % length(var.hana_disk_sizes_log))}"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "hana_disk_shared_to_vm_attachments" {
  count              = "${var.hana_node_count * length(var.hana_disk_sizes_shared)}"
  managed_disk_id    = "${azurerm_managed_disk.hana_disks_shared.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.hana_vms.*.id[count.index / length(var.hana_disk_sizes_shared)]}"
  lun                = "${1 + length(var.hana_disk_sizes_data) + length(var.hana_disk_sizes_log) + (count.index % length(var.hana_disk_sizes_shared))}"
  caching            = "ReadWrite"
}

# VIRTUAL MACHINEs ====================================================
resource "azurerm_virtual_machine" "hana_vms" {
  name                  = "${replace(var.hana_instance_name, "[num]", count.index)}"
  count                 = "${var.hana_node_count}"
  location              = "${var.hana_region}"
  resource_group_name   = "${var.hana_rg_name}"
  vm_size               = "${var.hana_vm_sku}"
  network_interface_ids = ["${local.hana_nic_ids[count.index]}"]

  storage_os_disk {
    name              = "${replace(var.hana_instance_name, "[num]", count.index)}-disk-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
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
