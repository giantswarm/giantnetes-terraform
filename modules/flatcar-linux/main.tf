data "external" "flatcar_version" {
  program = ["sh", "-c", "${path.module}/data/version.sh"]

  query = {
    aws_region = "${var.aws_region}"

    flatcar_channel = "${var.flatcar_channel}"
    flatcar_version = "${var.flatcar_version}"
  }
}
