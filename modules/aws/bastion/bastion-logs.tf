resource "aws_cloudwatch_log_group" "bastion_log_group" {
  name = "${var.cluster_name}"

  tags = {
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_cloudwatch_log_stream" "bastion_logs" {
  name           = "${var.cluster_name}_bastion_logs"
  log_group_name = "${aws_cloudwatch_log_group.bastion_log_group.name}"
}
