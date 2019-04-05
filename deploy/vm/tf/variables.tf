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
  hana_sizing_index = "${index(var.hana_available_sizes, upper(var.hana_size))}"
  hana_sizing       = "${var.hana_sizing[local.hana_sizing_index]}"
  hana_vm_sku       = "${local.hana_sizing["vm_sku"]}"
  hana_disk_labels  = "${split(",", local.hana_sizing["disk_labels"])}"
  hana_disk_sizes   = "${split(",", local.hana_sizing["disk_sizes"])}"
  hana_disk_counts  = "${split(",", local.hana_sizing["disk_counts"])}"
  hana_disk_types   = "${split(",", local.hana_sizing["disk_types"])}"
  hana_disk_caches  = "${split(",", local.hana_sizing["disk_caches"])}"
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
# hana_sites
#######################################################################

variable "hana_sites" {
  description = "List of HANA sites to create"
  type        = "list"
}

locals {
  empty_site = [{
    site_name     = ""
    region        = ""
    address_space = "0.0.0.0/0"
    subnet        = "0.0.0.0/0"
  }]

  hana_site_count = "${length(var.hana_sites)}"
  hana_sites      = "${concat(var.hana_sites, local.empty_site)}"
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
