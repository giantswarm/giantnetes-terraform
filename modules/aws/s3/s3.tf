locals {
  common_tags = merge(
    var.additional_tags,
    tomap({
      "giantswarm.io/cluster" =  var.cluster_name
      "giantswarm.io/installation" =  var.cluster_name
      "giantswarm.io/cluster-type" =  "control-plane"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    })
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
    tomap({
      "Name" = "${var.s3_bucket_prefix}${var.cluster_name}-access-logs"
    })
  )
}

resource "aws_s3_bucket_policy" "access-logs-policy" {
  bucket = aws_s3_bucket.logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ForceSSLOnlyAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logging.arn,
          "${aws_s3_bucket.logging.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket" "loki" {
  bucket        = "${var.cluster_name}-g8s-loki"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "Expiration"
    enabled = true

    expiration {
      days = var.loki_expiration_days
    }
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-g8s-loki"
    })
  )
}

resource "aws_s3_bucket_policy" "loki-policy" {
  bucket = aws_s3_bucket.loki.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ForceSSLOnlyAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.loki.arn,
          "${aws_s3_bucket.loki.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket" "mimir" {
  bucket        = "${var.cluster_name}-g8s-mimir"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "Expiration"
    enabled = true

    expiration {
      days = var.mimir_expiration_days
    }
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-g8s-mimir"
    })
  )
}

resource "aws_s3_bucket_policy" "mimir-policy" {
  bucket = aws_s3_bucket.mimir.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ForceSSLOnlyAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.mimir.arn,
          "${aws_s3_bucket.mimir.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket" "mimir-ruler" {
  bucket        = "${var.cluster_name}-g8s-mimir-ruler"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-g8s-mimir-ruler"
    })
  )
}

resource "aws_s3_bucket_policy" "mimir-ruler-policy" {
  bucket = aws_s3_bucket.mimir-ruler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ForceSSLOnlyAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.mimir-ruler.arn,
          "${aws_s3_bucket.mimir-ruler.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

resource "aws_s3_bucket" "tempo" {
  bucket        = "${var.cluster_name}-g8s-tempo"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "Expiration"
    enabled = true

    expiration {
      days = var.tempo_expiration_days
    }
  }

  tags = merge(
    local.common_tags,
    tomap({
      "Name" = "${var.cluster_name}-g8s-tempo"
    })
  )
}

resource "aws_s3_bucket_policy" "tempo-policy" {
  bucket = aws_s3_bucket.tempo.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ForceSSLOnlyAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tempo.arn,
          "${aws_s3_bucket.tempo.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
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
    tomap({
      "Name" = "${var.cluster_name}-ignition"
    })
  )
}

resource "aws_s3_bucket_policy" "ignition-policy" {
  bucket = aws_s3_bucket.ignition.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ForceSSLOnlyAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.ignition.arn,
          "${aws_s3_bucket.ignition.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
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
    tomap({
      "Name" = "${var.cluster_name}-ignition"
    })
  )
}
