variable "hana_available_sizes" {
  type    = "list"
  default = ["XS", "S"]
}

variable "hana_sizing" {
  type = "list"

  default = [
    {
      # XS
      vm_sku      = "Standard_D8s_v3"
      disk_labels = "os,hana,,,"
      disk_sizes  = "30,200,0,0"
      disk_counts = "1,1,0,0"
      disk_types  = "Standard_LRS,Standard_LRS,Standard_LRS,Standard_LRS"
      disk_caches = "ReadWrite,ReadWrite,ReadWrite,ReadWrite"
    },
    {
      # S
      vm_sku      = "Standard_D8s_v3"
      disk_labels = "os,data,log,shared"
      disk_sizes  = "30,100,200,50"
      disk_counts = "1,1,2,1"
      disk_types  = "Standard_LRS,Standard_LRS,Standard_LRS,Standard_LRS"
      disk_caches = "ReadWrite,ReadWrite,ReadWrite,ReadWrite"
    },
  ]
}
