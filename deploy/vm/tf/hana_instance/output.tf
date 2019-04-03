output "hello" {
  value = "${var.enabled ? var.hana_sid : "()"}"
}
