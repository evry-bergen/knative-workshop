# Terraform Setup

Terraform setup to spin up a complete Kubernetes runtime on Google Cloud.

## Structure

Description of files and directories within this directory.

| Path                             | Description |
|----------------------------------|-------------------------------------------|
| [`config/`](./env)               | Environment specific cofigurations        |
| [`modules/`](./modules)          | Directory with [Terraform moduler][terraform_module] |
| [`backend.tf`](./backend.tf)     | Configuration of [Terraform state backend][terraform_backend] |
| [`modules.tf`](./modules.tf)     | Configuration of Terraform modules in `/modules` |
| [`providers.tf`](./providers.tf) | Configuration of [Terraform providers][terraform_providers] |
| [`variables.tf`](./variables.tf) | Declaration of top level project variables |

[terraform_module]: https://www.terraform.io/docs/modules/index.html
[terraform_backend]: https://www.terraform.io/docs/backends/index.html
[terraform_providers]: https://www.terraform.io/docs/providers/google/index.html

## Prerequsite

* Google Cloud Platform (GCP) service account for Terraform
* Google Cloud Storage (GCS) bucket for Terraform state

## Config

```
$ export GOOGLE_CREDENTIALS $(cat ~/my/path.json | tr -d '\n')
$ export TERRAFORM_ENVIRONMENT dev
$ export TERRAFORM_STATE_GCP_BUCKET knative-workshop-tf-state
```

## Init

```
$ terraform init -reconfigure -backend-config="bucket=${TERRAFORM_STATE_GCP_BUCKET}"
$ terraform workspace new ${TERRAFORM_ENVIRONMENT}
```

## Plan

```
$ terraform plan -var-file=config/${TERRAFORM_ENVIRONMENT}.tfvars
```

## Apply

```
$ terraform apply -var-file=config/${TERRAFORM_ENVIRONMENT}.tfvars
```
