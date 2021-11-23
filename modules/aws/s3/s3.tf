locals {
  common_tags = merge(
    var.additional_tags,
    map(
      "giantswarm.io/cluster", var.cluster_name,
      "giantswarm.io/installation", var.cluster_name,
      "giantswarm.io/cluster-type", "control-plane",
      "kubernetes.io/cluster/${var.cluster_name}", "owned"
    )
  )
}

resource "aws_s3_bucket" "logging" {
  bucket        = "${var.s3_bucket_prefix}${var.cluster_name}-access-logs"
  acl           = "log-delivery-write"
  force_destroy = true

  logging {
    target_bucket = "${var.s3_bucket_prefix}${var.cluster_name}-access-logs"
    target_prefix = "self-logs/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "ExpirationLogs"
    enabled = true

    expiration {
      days = var.logs_expiration_days
    }
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.s3_bucket_prefix}${var.cluster_name}-access-logs"
    )
  )
}

resource "aws_s3_bucket" "ignition" {
  bucket        = "${var.aws_account}-${var.cluster_name}-ignition"
  acl           = "private"
  force_destroy = true

  logging {
    target_bucket = aws_s3_bucket.logging.id
    target_prefix = "${var.s3_bucket_prefix}${var.cluster_name}-ignition-logs/"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-ignition"
    )
  )
}

output "ignition_bucket_id" {
  value = aws_s3_bucket.ignition.id
}

output "logging_bucket_id" {
  value = aws_s3_bucket.logging.id
}

resource "aws_cloudwatch_log_group" "control-plane" {
  name              = "${var.cluster_name}-control-plane"
  retention_in_days = "90"

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-ignition"
    )
  )
}
