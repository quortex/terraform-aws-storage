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

output "buckets" {
  value = { for b in var.buckets : b["name"] => {
    "name" : try(aws_s3_bucket.quortex[b["name"]].bucket, null),
    "arn" : try(aws_s3_bucket.quortex[b["name"]].arn, null),
    "regional_domain_name" : try(aws_s3_bucket.quortex[b["name"]].bucket_regional_domain_name, null),
    "access_identity_path" : try(aws_cloudfront_origin_access_identity.quortex[b["name"]].cloudfront_access_identity_path, null),
    "region" : try(aws_s3_bucket.quortex[b["name"]].region, null),
    "label" : b["label"]
  } }
  description = "A map of bucket informations for each bucket provided in variables."
}

# The key ID to use for buckets access.
output "access_key_id" {
  value       = length(aws_iam_access_key.quortex) == 1 ? aws_iam_access_key.quortex[0].id : null
  description = "The key ID to use for buckets access."
}

# The key secret to use for buckets access.
output "access_key_secret" {
  value       = length(aws_iam_access_key.quortex) == 1 ? aws_iam_access_key.quortex[0].secret : null
  description = "The key secret to use for buckets access."
  sensitive   = true
}
