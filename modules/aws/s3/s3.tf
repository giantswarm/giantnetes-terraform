locals {
  common_tags = "${map(
    "giantswarm.io/installation", "${var.cluster_name}",
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )}"
}

resource "aws_s3_bucket" "ignition" {
  bucket        = "${var.aws_account}-${var.cluster_name}-ignition"
  acl           = "private"
  force_destroy = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-ignition"
    )
  )}"
}

output "ignition_bucket_id" {
  value = "${aws_s3_bucket.ignition.id}"
}
