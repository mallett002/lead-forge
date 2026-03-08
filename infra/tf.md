1. Install Terraform

Verify it's installed.

terraform -version

If not installed (Mac with brew):

brew install terraform
2. Create the Project Folder

Example:

mkdir terraform-infra
cd terraform-infra

Typical minimal structure:

terraform-infra/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
└── .gitignore

For now you only need main.tf, but separating files is best practice.

3. Define the Provider

Create providers.tf

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

This tells Terraform:

what providers to download

which version

AWS region

4. Add Your First Resource

Create main.tf

Example: S3 bucket

resource "aws_s3_bucket" "example" {
  bucket = "my-terraform-demo-bucket-123456"

  tags = {
    Name = "TerraformDemo"
  }
}
5. Initialize Terraform

Run:

terraform init

This:

downloads providers

creates .terraform/

prepares the project

6. Preview the Infrastructure
terraform plan

Shows what will be created.

7. Apply It
terraform apply

Confirm with yes.

Terraform will create the resource.

8. Destroy (when testing)
terraform destroy
9. Add .gitignore

Important so you don't commit Terraform state locally.

.terraform/
*.tfstate
*.tfstate.*
.terraform.lock.hcl
10. Real World Best Practice (VERY important)

In real systems you never store state locally.

Use remote state like S3.

Example:

terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "global/terraform.tfstate"
    region = "us-east-1"
  }
}
Simple Workflow

Typical workflow becomes:

terraform init
terraform plan
terraform apply

