resource "aws_iam_role" "cc_role" {
  name = "lambda-sqs-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_sqs_assume_role.json
}

data "aws_iam_policy_document" "lambda_sqs_assume_role" {
  statement {
    sid    = "AllowLambdaAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "cc_policy" {
  name        = "lambda_sqs_policy"
  description = "IAM policy for sqs Lambda"

  policy = data.aws_iam_policy_document.cc_doc.json
}

data "aws_iam_policy_document" "cc_doc" {
  statement {
    sid    = "AllowLambdaCreateLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:ListTagsLogGroup",
      "tag:GetResources",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowLambdaToReadMessage"
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      aws_sqs_queue.cc_queue.arn,
    ]
  }
  statement {
    sid    = "AllowLambdaToInvokeApi"
    effect = "Allow"
    actions = [
      "execute-api:Invoke",
    ]

    resources = ["*"]
  }
  statement {
    sid    = "AllowLambdaDecrptMessage"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      aws_kms_key.cc_sqs_queue.arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cc_sqs_lambda" {
  role       = aws_iam_role.cc_role.name
  policy_arn = aws_iam_policy.cc_policy.arn
}


resource "aws_lambda_function" "logging_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = local.lambda_name
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.cc_role.arn

  runtime     = "python3.9"
  timeout     = 30
  memory_size = 1024
  tags        = var.config_tags
}

variable "config_tags" {
  type = any
  default = {
    Team = "DevOps"
  }
}

locals {
  lambda_name      = "logging-lambda"
  lambda_role_name = "logging-role"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda.py"
  output_path = "${path.module}/src/lambda.py.zip"
}

resource "aws_lambda_event_source_mapping" "sqs_lambda" {
  event_source_arn = aws_sqs_queue.cc_queue.arn
  function_name    = aws_lambda_function.logging_lambda.arn
  enabled          = true

  depends_on = [
    aws_sqs_queue_policy.cc_queue_policy
  ]
}

resource "aws_sqs_queue" "cc_queue" {
  name                              = "logging-queue"
  delay_seconds                     = 10
  receive_wait_time_seconds         = 10
  kms_master_key_id                 = "alias/cc_sqs_kms"
  kms_data_key_reuse_period_seconds = 300

}

resource "aws_sqs_queue_policy" "cc_queue_policy" {
  queue_url = aws_sqs_queue.cc_queue.id

  policy = data.aws_iam_policy_document.cc_sqs.json
}

data "aws_iam_policy_document" "cc_sqs" {
  statement {
    sid    = "AllowIntegrationsAccForSqs"
    effect = "Allow"
    actions = [
      "sqs:*"
    ]

    principals {
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
      type = "AWS"
    }

    resources = ["*"]
  }

  statement {
    sid    = "IntegrationsAccForS3"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    principals {
      identifiers = [
        "s3.amazonaws.com"
      ]
      type = "service"
    }

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage", "sqs:*"]
    resources = ["arn:aws:sqs:*:*:logging-queue"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.bucket.arn]
    }
  }

  statement {
    sid    = "Allow all prinicipals in org to send to queue"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgId"
      values = [
        data.aws_organizations_organization.this.id
      ]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "this" {}





