output "coreos_version" {
  value = "${var.coreos_version == "latest" ? data.external.coreos_version.result["coreos_version"] : var.coreos_version}"
}
