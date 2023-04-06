<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
[![Quortex][logo]](https://quortex.io)

# terraform-aws-storage

A terraform module for Quortex infrastructure AWS persistent storage layer.

It provides a set of resources necessary to provision the bucket and access key on Amazon AWS.

![infra_diagram]

This module is available on [Terraform Registry][registry_tf_aws-eks_storage].

Get all our terraform modules on [Terraform Registry][registry_tf_modules] or on [Github][github_tf_modules] !

## Created resources

This module creates the following resources in AWS:
- as many buckets in Amazon S3 as defined in the configuration
- a new user, with access to the bucket
- the key ID and secret for this user


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.38.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_buckets"></a> [buckets](#input\_buckets) | The list of buckets to create. | <pre>set(<br>    object({<br>      name  = string<br>      label = string<br>      tags  = map(string)<br>      expiration = optional(object({<br>        enabled         = bool<br>        expiration_days = number<br>      }))<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_storage_prefix"></a> [storage\_prefix](#input\_storage\_prefix) | A prefix for bucket names and service account id. Bucket names will be computed from this prefix and the provided buckets variable. | `string` | `"quortex"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | When deleting a bucket, this boolean option will delete all contained objects. If you try to delete a bucket that contains objects, Terraform will fail that run. | `bool` | `false` | no |
| <a name="input_enable_bucket_encryption"></a> [enable\_bucket\_encryption](#input\_enable\_bucket\_encryption) | Should the created bucket encrypted using SSE-S3. | `bool` | `true` | no |
| <a name="input_enable_cloudfront_oia"></a> [enable\_cloudfront\_oia](#input\_enable\_cloudfront\_oia) | Wether to enable cloudfront origin access identity for buckets. | `bool` | `false` | no |
| <a name="input_sa_path"></a> [sa\_path](#input\_sa\_path) | The path to assign to bucket's service account. | `string` | `"/system/"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources. A list of key->value pairs. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_buckets"></a> [buckets](#output\_buckets) | A map of bucket informations for each bucket provided in variables. |
| <a name="output_access_key_id"></a> [access\_key\_id](#output\_access\_key\_id) | The key ID to use for buckets access. |
| <a name="output_access_key_secret"></a> [access\_key\_secret](#output\_access\_key\_secret) | The key secret to use for buckets access. |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_origin_access_identity.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_iam_access_key.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_user.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.quortex_bucket_rw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_s3_bucket.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_iam_policy_document.quortex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |


---

## Related Projects

This project is part of our terraform modules to provision a Quortex infrastructure for AWS.

Check out these related projects.

- [terraform-aws-network][registry_tf_aws-eks_network] - A terraform module for Quortex infrastructure network layer.

- [terraform-aws-eks-cluster][registry_tf_aws-eks_cluster] - A terraform module for Quortex infrastructure AWS cluster layer.

- [terraform-aws-eks-load-balancer][registry_tf_aws-eks_load_balancer] - A terraform module for Quortex infrastructure AWS load balancing layer.

[logo]: https://storage.googleapis.com/quortex-assets/logo.webp
[infra_diagram]: https://storage.googleapis.com/quortex-assets/infra_aws_001.jpg

[registry_tf_modules]: https://registry.terraform.io/modules/quortex
[registry_tf_aws-eks_network]: https://registry.terraform.io/modules/quortex/network/aws
[registry_tf_aws-eks_cluster]: https://registry.terraform.io/modules/quortex/eks-cluster/aws
[registry_tf_aws-eks_load_balancer]: https://registry.terraform.io/modules/quortex/load-balancer/aws
[registry_tf_aws-eks_storage]: https://registry.terraform.io/modules/quortex/storage/aws
[github_tf_modules]: https://github.com/quortex?q=terraform-


## Help

**Got a question?**

File a GitHub [issue](https://github.com/quortex/terraform-aws-storage/issues).
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
