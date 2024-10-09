locals {
  common_tags = merge(
    var.additional_tags,
    tomap({
      "giantswarm.io/cluster" =  var.cluster_name
      "giantswarm.io/installation" = var.cluster_name
      "giantswarm.io/cluster-type" =  "control-plane"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    })
  )

  queue_name = "${var.cluster_name}-node-termination"
}

resource "aws_sqs_queue" "node_termination_queue" {
  name                      = local.queue_name
  message_retention_seconds = 300
  policy                    = <<EOT
    {
      "Version": "2012-10-17",
      "Id": "NodeTerminationQueuePolicy",
      "Statement":
      [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": ["events.amazonaws.com", "sqs.amazonaws.com"]
          },
          "Action": "sqs:SendMessage",
          "Resource": [
            "arn:aws:sqs:${var.aws_region}:${var.aws_account}:${local.queue_name}"
          ]
        }
      ]
    }
EOT

  tags = local.common_tags
}
