variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

#######################################################################
# hana_sid
#######################################################################

variable "hana_sid" {
  description = "HANA SID (values: 3 characters/digits)"
}

locals {
  incorrect_hana_sid = "${length(var.hana_sid) != 3 ? 1 : 0}"
  hana_sid           = "${upper(var.hana_sid)}"
}

resource "null_resource" "incorrect_hana_sid" {
  count                                           = "${local.incorrect_hana_sid}"
  "ERROR: <hana_sid> must be 3 characters/digits" = true
}

#######################################################################
# hana_instance_num
#######################################################################

variable "hana_instance_num" {
  description = "HANA instance number (values: 00-99)"
}

locals {
  incorrect_hana_instance_num = "${var.hana_instance_num < 0 || var.hana_instance_num > 99 || length(var.hana_instance_num) != 2 ? 1 : 0}"
  hana_instance_num           = "${var.hana_instance_num}"
}

resource "null_resource" "incorrect_hana_instance_num" {
  count                                               = "${local.incorrect_hana_instance_num}"
  "ERROR: <hana_instance_num> must between 00 and 99" = true
}

#######################################################################
# hana_node_count
#######################################################################

variable "hana_node_count" {
  description = "Number of HANA nodes (currently only 1 is supported)"
  default     = 1
}

locals {
  incorrect_hana_node_count = "${var.hana_node_count > 5 ? 1 : 0}"
  hana_node_count           = "${var.hana_node_count}"
}

resource "null_resource" "incorrect_hana_node_count" {
  count                                              = "${local.incorrect_hana_node_count}"
  "ERROR: <hana_node_count> must be 1 (single-node)" = true
}

#######################################################################
# hana_size
#######################################################################

variable "hana_size" {
  description = "HANA size"
}

locals {
  hana_sizing_index      = "${index(var.hana_available_sizes, upper(var.hana_size))}"
  hana_sizing            = "${var.hana_sizing[local.hana_sizing_index]}"
  hana_vm_sku            = "${local.hana_sizing["vm_sku"]}"
  hana_disk_sizes_data   = "${split(",", local.hana_sizing["disk_sizes_data"])}"
  hana_disk_sizes_log    = "${split(",", local.hana_sizing["disk_sizes_log"])}"
  hana_disk_sizes_shared = "${split(",", local.hana_sizing["disk_sizes_shared"])}"
}

#######################################################################
# hana_enable_ha
#######################################################################

variable "hana_enable_ha" {
  description = "Whether to deploy an HA HANA instance (values: true|false)"
  default     = false
}

locals {
  hana_enable_ha = "${var.hana_enable_ha}"
}

#######################################################################
# hana_use_az
#######################################################################

variable "hana_use_az" {
  description = "Whether to use Azure Availability Zones (values: true|false)"
  default     = false
}

#######################################################################
# hana_regions
#######################################################################

variable "hana_region" {
  description = "Azure region to deploy HANA"
  default     = ""
}

variable "hana_region_primary" {
  description = "Azure region to deploy HANA in primary site"
  default     = "abc"
}

variable "hana_region_secondary" {
  description = "Azure region to deploy HANA in secondary site"
  default     = "abc"
}

locals {
  hana_regions_tmp     = ["${local.hana_enable_ha ? var.hana_region_primary : var.hana_region}", "${local.hana_enable_ha ? var.hana_region_secondary : ""}"]
  hana_regions         = "${compact(local.hana_regions_tmp)}"
  missing_hana_regions = "${((local.hana_enable_ha && length(local.hana_regions) < 2) || (!local.hana_enable_ha && length(local.hana_regions) != 1)) ? 1 : 0}"
}

resource "null_resource" "missing_hana_regions" {
  count                                                                                                                                   = "${local.missing_hana_regions}"
  "ERROR: need to specify Azure regions (<hana_region> for non-HA; <hana_region_primary> and <hana_region_secondary> for HA deployments)" = true
}

#######################################################################
# hana_address_space
#######################################################################

variable "hana_address_space" {
  description = "VNET address space to deploy HANA"
  default     = ""
}

variable "hana_address_space_primary" {
  description = "VNET address space to deploy HANA (primary)"
  default     = ""
}

variable "hana_address_space_secondary" {
  description = "VNET address space to deploy HANA (secondary"
  default     = ""
}

locals {
  hana_address_spaces_tmp     = ["${local.hana_enable_ha ? var.hana_address_space_primary : var.hana_address_space}", "${local.hana_enable_ha ? var.hana_address_space_secondary : ""}"]
  hana_address_spaces         = "${compact(local.hana_address_spaces_tmp)}"
  missing_hana_address_spaces = "${((local.hana_enable_ha && length(local.hana_address_spaces) < 2) || (!local.hana_enable_ha && length(local.hana_address_spaces) != 1)) ? 1 : 0}"
}

resource "null_resource" "missing_hana_address_spaces" {
  count                                                                                                                                                             = "${local.missing_hana_address_spaces}"
  "ERROR: need to specify VNET address space (<hana_address_space> for non-HA; <hana_address_space_primary> and <hana_address_space_secondary> for HA deployments)" = true
}

#######################################################################
# hana_subnets
#######################################################################

variable "hana_subnet" {
  description = "Subnet to deploy HANA"
  default     = ""
}

variable "hana_subnet_primary" {
  description = "Subnet to deploy HANA (primary)"
  default     = ""
}

variable "hana_subnet_secondary" {
  description = "Subnet to deploy HANA (secondary)"
  default     = ""
}

locals {
  hana_subnets_tmp     = ["${local.hana_enable_ha ? var.hana_subnet_primary : var.hana_subnet}", "${local.hana_enable_ha ? var.hana_subnet_secondary : ""}"]
  hana_subnets         = "${compact(local.hana_subnets_tmp)}"
  missing_hana_subnets = "${((local.hana_enable_ha && length(local.hana_subnets) < 2) || (!local.hana_enable_ha && length(local.hana_subnets) != 1)) ? 1 : 0}"
}

resource "null_resource" "missing_hana_subnets" {
  count                                                                                                                             = "${local.missing_hana_subnets}"
  "ERROR: need to specify subnets (<hana_subnet> for non-HA; <hana_subnet_primary> and <hana_subnet_secondary> for HA deployments)" = true
}

#######################################################################
# hana_enable_public
#######################################################################

variable "hana_enable_public_ip" {
  description = "Whether to enable a public IP for the HANA VM(s) (values: true|false)"
  default     = false
}

locals {
  hana_enable_public_ip = "${var.hana_enable_public_ip}"
}

#######################################################################
# allowed_ip_ranges
#######################################################################

variable "allowed_ip_ranges" {
  description = "IP ranges allowed for access from internet (values: [\"<ip_range-1>\"[,\"<ip_range-2>\"])"
  type        = "list"
  default     = ["*"]
}

locals {
  allowed_ip_ranges         = "${var.allowed_ip_ranges}"
  missing_allowed_ip_ranges = "${(local.hana_enable_public_ip && length(local.allowed_ip_ranges) == 0) ? 1 : 0}"
}

resource "null_resource" "missing_allowed_ip_ranges" {
  count                                                                                                     = "${local.missing_allowed_ip_ranges}"
  "ERROR: need to specify allowed IP ranges when enabling public IP (use [\"*\"] for all address prefixes)" = true
}

#######################################################################
# hana_enable_ssh_access
#######################################################################

variable "hana_enable_ssh_access" {
  description = "Whether to allow SSH access (port 22) to HANA VM and create a NSG rule (values: true|false)"
  default     = true
}

locals {
  hana_enable_ssh_access = "${var.hana_enable_ssh_access}"
}

#######################################################################
# hana_enable_hdb_access
#######################################################################

variable "hana_enable_hdb_access" {
  description = "Whether to allow HDB access (ports 3XX00-3XX99) to HANA VM and create a NSG rule (values: true|false)"
  default     = true
}

locals {
  hana_enable_hdb_access = "${var.hana_enable_hdb_access}"
}

#######################################################################
# hana_vm_username
#######################################################################

variable "hana_vm_username" {
  description = "HANA VM username"
  default     = "vmadmin"
}

locals {
  hana_vm_username = "${var.hana_vm_username}"
}

#######################################################################
# label_rg
#######################################################################

variable "label_rg" {
  description = "Resource group name (can use [hana_sid], [hana_instance_num])"
  default     = "hana_[hana_sid][hana_instance_num]"
}

locals {
  rg_name = "${replace(replace(replace(var.label_rg, "[HANA_SID]", local.hana_sid), "[hana_instance_num]", local.hana_instance_num), "[hana_sid]", lower(local.hana_sid))}"
}

#######################################################################
# label_prefix
#######################################################################

variable "label_prefix" {
  description = "Resource prefix (can use [hana_sid], [hana_instance_num])"
  default     = "[hana_sid]-"
}

locals {
  resource_prefix = "${replace(replace(replace(var.label_prefix, "[HANA_SID]", local.hana_sid), "[hana_instance_num]", local.hana_instance_num), "[hana_sid]", lower(local.hana_sid))}"
}

#######################################################################
# label_instance
#######################################################################

variable "label_instance" {
  description = "Instance label (can use [prefix], [type], [num], [site])"
  default     = "[prefix][type][num][site]"
}

locals {
  label_instance = "${replace(var.label_instance, "[prefix]", local.resource_prefix)}"
}
