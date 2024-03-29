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

variable "buckets" {
  type = set(
    object({
      name  = string
      label = string
      tags  = map(string)
      expiration = optional(object({
        enabled         = bool
        expiration_days = number
      }))
      role = optional(object({
        service_accounts = list(object({
          name      = string
          namespace = string
        }))
      }))
    })
  )
  default     = []
  description = "The list of buckets to create."
}

variable "storage_prefix" {
  type        = string
  default     = "quortex"
  description = "A prefix for bucket names and service account id. Bucket names will be computed from this prefix and the provided buckets variable."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run."
}

variable "enable_bucket_encryption" {
  type        = bool
  description = "Should the created bucket encrypted using SSE-S3."
  default     = true
}

variable "enable_cloudfront_oia" {
  type        = bool
  default     = false
  description = "Wether to enable cloudfront origin access identity for buckets."
}

variable "sa_path" {
  type        = string
  default     = "/system/"
  description = "The path to assign to bucket's service account."
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources. A list of key->value pairs."
  default     = {}
}

variable "cluster_oidc_issuer" {
  type        = string
  description = "The cluster OpenID Connect Issuer."
  default     = ""
}

variable "enable_irsa" {
  type        = bool
  description = "Enable roles related to IRSA"
  default     = false
}

variable "enable_user_access_key" {
  type        = bool
  description = "Enable user and access key"
  default     = true
}
