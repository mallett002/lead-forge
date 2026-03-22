# lead-forge

### Terraform
#### bootstrap
- Sets up terraform state and locking (s3 and dynamo)
- `/bootstrap`

#### infra
- Sets up actualy infrastructure for application
- `/infra`

#### Creating static site:
- Run bootstrap to set up terraform state and locking
    - `cd bootstrap`
    - `terraform plan -out=bootstrap`
    - `terraform apply "bootstrap"`

- Create infra for website:
    - manually create hosted zone in aws
    - `cd infra`
    - `terraform plan -out=tfplan`
    - `terraform apply "tfplan"`

- Visit `farmtotablenearme.com`

