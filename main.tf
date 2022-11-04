/**
 * Copyright 2020 Quortex
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# --- Buckets's IAM ---

# Service account
resource "aws_iam_user" "quortex" {
  count = length(local.buckets) > 0 ? 1 : 0
  name  = "${var.storage_prefix}-storage"
  path  = var.sa_path

  tags = var.tags
}

locals {
  buckets = toset([for b in var.buckets : b["name"]])
}

# Key
resource "aws_iam_access_key" "quortex" {
  count = length(local.buckets) > 0 ? 1 : 0
  user  = aws_iam_user.quortex[count.index].name
}
resource "aws_iam_user_policy" "quortex_bucket_rw" {
  for_each = local.buckets
  name     = "${var.storage_prefix}-${each.value}-rw"
  user     = aws_iam_user.quortex[0].name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListObjectsInBuckets",
      "Action": [
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.quortex[each.value].arn}"
      ]
    },
    {
      "Sid": "AllObjectActions",
      "Action": [
        "s3:*Object"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.quortex[each.value].arn}/*"
      ]
    }
  ]
}
EOF
}


# --- Buckets ---

# The S3 buckets.
resource "aws_s3_bucket" "quortex" {
  for_each = local.buckets

  bucket        = "${var.storage_prefix}-${each.value}"
  force_destroy = var.force_destroy

  tags = var.tags

  # Empty bucket content before destroy to improves the bucket destruction time
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      ${!self.force_destroy} && exit
      echo 'emptying ${self.bucket} bucket'
      aws s3 rm s3://${self.bucket} --recursive --quiet
    EOT
  }
}

resource "aws_s3_bucket_acl" "quortex" {
  for_each = local.buckets

  bucket = aws_s3_bucket.quortex[each.value].id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "quortex" {
  for_each = var.expiration != null && var.expiration.enabled ? local.buckets : toset([])

  bucket = aws_s3_bucket.quortex[each.value].id
  rule {
    id     = "expiration"
    status = "Enabled"
    expiration {
      days = var.expiration.expiration_days
    }
  }
}

# Set minimal encryption on buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "quortex" {
  for_each = var.enable_bucket_encryption ? local.buckets : toset([])
  bucket   = aws_s3_bucket.quortex[each.value].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "quortex" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.quortex[each.value].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin access identity to allow acces from cloudfront
resource "aws_cloudfront_origin_access_identity" "quortex" {
  for_each = var.enable_cloudfront_oia ? local.buckets : []

  comment = "Access identity for bucket ${aws_s3_bucket.quortex[each.value].bucket} access"
}

# Bucket access policy
data "aws_iam_policy_document" "quortex" {
  for_each = var.enable_cloudfront_oia ? local.buckets : []

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.quortex[each.value].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.quortex[each.value].iam_arn]
    }
  }
}

# Apply bucket policy
resource "aws_s3_bucket_policy" "quortex" {
  for_each = var.enable_cloudfront_oia ? local.buckets : []

  bucket = aws_s3_bucket.quortex[each.value].id
  policy = data.aws_iam_policy_document.quortex[each.value].json
}
