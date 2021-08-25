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
  count = length(var.buckets) > 0 ? 1 : 0
  name  = "${var.storage_prefix}-storage"
  path  = var.sa_path

  tags = var.tags
}

# Key
resource "aws_iam_access_key" "quortex" {
  count = length(var.buckets) > 0 ? 1 : 0
  user  = aws_iam_user.quortex[count.index].name
}
resource "aws_iam_user_policy" "quortex_bucket_rw" {
  for_each = var.buckets
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
  for_each = var.buckets

  bucket        = "${var.storage_prefix}-${each.value}"
  acl           = "private"
  force_destroy = var.force_destroy

  dynamic "lifecycle_rule" {
    for_each = var.expiration != null ? [true] : []
    content {
      enabled = var.expiration.enabled
      expiration {
        days = var.expiration.expiration_days
      }
    }
  }

  tags = var.tags

  # Empty bucket content before destroy to improves the bucket destruction time
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      ${self.force_destroy} && aws s3 rm s3://${self.bucket} --recursive --quiet
    EOT
  }
}
