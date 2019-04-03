output "hana_subnets" {
  value = "${local.hana_subnets}"
}

# output "hana_sizing" {
#   value = "${local.hana_sizing}"
# }

output "hana1-hello" {
  value = "${module.hana_instance_1.hello}"
}

# output "hana2-hello" {
#   value = "${module.hana_instance_2.hello}"
# }

