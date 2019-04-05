output "availability_set_id" {
  value = "${var.enabled ? join(",", azurerm_availability_set.hana_availability_set.*.id) : "" }"
}

output "vnet_name" {
  value = "${var.enabled ? join(",", azurerm_virtual_network.hana_vnet.*.name) : "" }"
}
