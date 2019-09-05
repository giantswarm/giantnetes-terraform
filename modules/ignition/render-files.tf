resource "template_dir" "config" {
  source_dir      = "../../../templates/files"
  destination_dir = "../../../files"

  vars = "${var.ignition_data}"
}
