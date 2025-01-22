###
# Resource Policy for SQS KMS
###
data "aws_iam_policy_document" "cc_sqs_kms" {
  statement {
    sid    = "EnableIAMPolicies"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
      type = "AWS"
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgId"
      values = [
        data.aws_organizations_organization.this.id,
      ]
    }
  }
}
