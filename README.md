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
    - `cd infra`
    - `terraform plan -out=tfplan`
    - `terraform apply "tfplan"`

- Visit `https://lead-forge-website-s3-bucket.s3.amazonaws.com/index.html`

