resource "aws_s3_bucket" "cloudconfig" {
  bucket        = "${var.aws_account}-${var.cluster_name}-cloudinit"
  acl           = "private"
  force_destroy = true

  tags {
    Name        = "${var.cluster_name}-cloudconfig"
    Environment = "${var.cluster_name}"
  }
}

output "cloudconfig_bucket_id" {
  value = "${aws_s3_bucket.cloudconfig.id}"
}
