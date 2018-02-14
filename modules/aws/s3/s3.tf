resource "aws_s3_bucket" "ignition" {
  bucket        = "${var.aws_account}-${var.cluster_name}-ignition"
  acl           = "private"
  force_destroy = true

  tags {
    Name        = "${var.cluster_name}-ignition"
    Environment = "${var.cluster_name}"
  }
}

output "ignition_bucket_id" {
  value = "${aws_s3_bucket.ignition.id}"
}
