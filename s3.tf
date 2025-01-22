resource "aws_s3_bucket" "bucket" {
  bucket = lower("${random_pet.pet-name.id}-${random_integer.int.result}")
  force_destroy = true

  tags = {
    Name        = "prod-buc"
  }
}

resource "random_pet" "pet-name" {
  length = 3
  prefix = "WEMA"
}

resource "random_integer" "int" {
  max = 500
  min = 1
}

resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  queue {
    queue_arn     = aws_sqs_queue.cc_queue.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_suffix = ".log"
  }
}