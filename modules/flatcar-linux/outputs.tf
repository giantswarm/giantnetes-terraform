output "flatcar_version" {
  value = var.flatcar_version == "latest" ? data.external.flatcar_version.result["flatcar_version"] : var.flatcar_version
}
