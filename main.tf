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
  buckets = {
    for b in var.buckets : b["name"] => b
  }
}

# Key
resource "aws_iam_access_key" "quortex" {
  count = length(local.buckets) > 0 ? 1 : 0
  user  = aws_iam_user.quortex[count.index].name
}

resource "aws_iam_user_policy" "quortex_bucket_rw" {
  for_each = local.buckets
  name     = "${var.storage_prefix}-${each.key}-rw"
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
        "${aws_s3_bucket.quortex[each.key].arn}"
      ]
    },
    {
      "Sid": "AllObjectActions",
      "Action": [
        "s3:*Object"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.quortex[each.key].arn}/*"
      ]
    }
  ]
}
EOF
}

# --- Roles and policies associated to irsa ---
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "aws_eks_irsa" {
  for_each           = var.enable_irsa ? local.buckets : []
  name               = "${var.storage_prefix}-${each.key}-irsa"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role_policy[each.key].json
}

resource "aws_iam_policy" "aws_eks_irsa" {
  for_each    = var.enable_irsa ? local.buckets : []
  name        = "${var.storage_prefix}-${each.key}-irsa"
  description = "The permissions required by service account to assume roles."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "ListObjectsInBuckets",
        Action = [
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.quortex[each.key].arn
        ]
      },
      {
        Sid = "AllObjectActions",
        Action = [
          "s3:*Object"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.quortex[each.key].arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_eks_irsa" {
  for_each   = var.enable_irsa ? local.buckets : []
  role       = aws_iam_role.aws_eks_irsa[each.key].name
  policy_arn = aws_iam_policy.aws_eks_irsa[each.key].arn
}

data "aws_iam_policy_document" "irsa_assume_role_policy" {
  for_each = var.enable_irsa ? local.buckets : []
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.cluster_oidc_issuer}"]
    }

    dynamic "condition" {
      for_each = each.value.role.enabled ? [1] : []
      content {
        test     = "StringLike"
        variable = "${var.cluster_oidc_issuer}:sub"
        values   = [for a in each.value.role.service_accounts : "system:serviceaccount:${a.namespace}:${a.name}"]
      }
    }

    dynamic "condition" {
      for_each = each.value.role.enabled ? [1] : []
      content {
        test     = "StringLike"
        variable = "${var.cluster_oidc_issuer}:aud"
        values   = ["sts.amazonaws.com"]
      }
    }
  }
}

# --- Buckets ---

# The S3 buckets.
resource "aws_s3_bucket" "quortex" {
  for_each = local.buckets

  bucket        = "${var.storage_prefix}-${each.key}"
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    each.value.tags
  )

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

resource "aws_s3_bucket_lifecycle_configuration" "quortex" {
  for_each = { for k, v in local.buckets : k => v if try(v.expiration.enabled, false) }

  bucket = aws_s3_bucket.quortex[each.key].id
  rule {
    id     = "expiration"
    status = "Enabled"
    expiration {
      days = each.value.expiration.expiration_days
    }
  }
}

# Set minimal encryption on buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "quortex" {
  for_each = var.enable_bucket_encryption ? local.buckets : {}
  bucket   = aws_s3_bucket.quortex[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "quortex" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.quortex[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin access identity to allow acces from cloudfront
resource "aws_cloudfront_origin_access_identity" "quortex" {
  for_each = var.enable_cloudfront_oia ? local.buckets : {}

  comment = "Access identity for bucket ${aws_s3_bucket.quortex[each.key].bucket} access"
}

# Bucket access policy
data "aws_iam_policy_document" "quortex" {
  for_each = var.enable_cloudfront_oia ? local.buckets : {}

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.quortex[each.key].arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.quortex[each.key].iam_arn]
    }
  }
}

# Apply bucket policy
resource "aws_s3_bucket_policy" "quortex" {
  for_each = var.enable_cloudfront_oia ? local.buckets : {}

  bucket = aws_s3_bucket.quortex[each.key].id
  policy = data.aws_iam_policy_document.quortex[each.key].json
}
