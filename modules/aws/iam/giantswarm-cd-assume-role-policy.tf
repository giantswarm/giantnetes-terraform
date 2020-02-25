# allow conveyor user to assume root role from GS account

data "aws_iam_policy_document" "giantswarm-cd-assume-role-policy" {
  statement {
    effect        = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.gs_aws_account}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test        = "StringEquals"
      variable    = "sts.ExternalId"
      values = ["${var.sts_external_id}"]
    }
  }
}
