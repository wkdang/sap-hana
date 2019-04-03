variable "hana_available_sizes" {
  type    = "list"
  default = ["XS", "S"]
}

variable "hana_sizing" {
  type = "list"

  default = [
    {
      # XS
      vm_sku = "Standard_D8s_v3"

      # disk_sizes        = ["30,200,100,50"]
      # disk_counts       = ["1,2,2,1"]
      # disk_types        = ["Standard_LRS,Standard_LRS,Standard_LRS,Standard_LRS"]
      disk_sizes_data = "200,200"

      disk_sizes_log    = "100,100"
      disk_sizes_shared = "50"
    },
  ]
}
