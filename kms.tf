resource "aws_kms_key" "cc_sqs_queue" {
  bypass_policy_lockout_safety_check = false
  description                        = "KMS Key used for cloud custodian outputs archive encryption"
  deletion_window_in_days            = 30
  key_usage                          = "ENCRYPT_DECRYPT"
  is_enabled                         = true
  enable_key_rotation                = true # Next rotation due 01/10/2024
  multi_region                       = true
  policy                             = data.aws_iam_policy_document.cc_sqs_kms.json

}

resource "aws_kms_alias" "cc_sqs_kms" {
  name          = "alias/cc_sqs_kms"
  target_key_id = aws_kms_key.cc_sqs_queue.key_id
}