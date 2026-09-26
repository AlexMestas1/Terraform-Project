# Terraform-Project

[![Terraform](https://github.com/AlexMestas1/Terraform-Project/actions/workflows/terraform.yml/badge.svg)](https://github.com/AlexMestas1/Terraform-Project/actions/workflows/terraform.yml)

Basic Terraform setup that spins up a single EC2 instance on AWS and
installs a demo website on it.

## What it does

- Uses the account's default VPC and subnet for the region
- Creates a security group allowing HTTP (80) from anywhere and SSH (22)
  from my own IP only
- Looks up the latest x86_64 Amazon Linux 2023 AMI through the public SSM
  parameter (Amazon Linux 2 reached end of support in June 2026)
- Launches an EC2 instance with an encrypted root volume and IMDSv2
  required, and runs `install_website.sh` on boot, which installs Apache
  and drops in a small static demo page

## Requirements

- Terraform 1.5 or newer (CI runs 1.8.5)
- An AWS account with an AWS CLI profile set up. The profile needs
  `ssm:GetParameter` for the AMI lookup, on top of the EC2 permissions
- An existing EC2 key pair, name set with the `key_name` variable
  (defaults to `myec2key`)
- An S3 bucket for the Terraform state file

## Usage

```
terraform init
terraform plan -var="my_ip=YOUR_IP_HERE"
terraform apply -var="my_ip=YOUR_IP_HERE"
```

`my_ip` should just be the bare address, e.g. `203.0.113.5`, not a CIDR
block. The security group rule appends `/32` itself.

Terraform prints the site's URL and an ssh command when it's done.

To avoid typing the variables every time, copy `terraform.tfvars.example`
to `terraform.tfvars` and fill it in. That file is gitignored.

CI runs `terraform fmt`, `validate` and `tflint` on every push. It doesn't
run a plan, since that needs AWS credentials.

To tear everything down:

```
terraform destroy
```
