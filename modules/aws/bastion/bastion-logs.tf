resource "aws_cloudwatch_log_group" "bastion_log_group" {
  count = "${ var.forward_logs_enabled ? 1 : 0 }"
  name  = "${var.cluster_name}_bastion"

  tags = {
    "giantswarm.io/installation" = "${var.cluster_name}"
  }
}

resource "aws_cloudwatch_log_stream" "bastion_logs" {
  count          = "${ var.forward_logs_enabled ? 1 : 0 }"
  name           = "${var.cluster_name}_bastion"
  log_group_name = "${aws_cloudwatch_log_group.bastion_log_group.name}"
}
