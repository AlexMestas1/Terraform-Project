# Terraform-Project

[![Terraform](https://github.com/AlexMestas1/Terraform-Project/actions/workflows/terraform.yml/badge.svg)](https://github.com/AlexMestas1/Terraform-Project/actions/workflows/terraform.yml)

Basic Terraform setup that spins up a single EC2 instance on AWS and
installs a demo website on it.

## What it does

- Uses the account's default VPC and subnet for the region
- Creates a security group allowing HTTP (80) from anywhere and SSH (22)
  from my own IP only
- Looks up the latest Amazon Linux 2 AMI
- Launches an EC2 instance and runs `install_website.sh` on boot, which
  installs Apache and drops in a small static demo page

## Requirements

- Terraform
- An AWS account with an AWS CLI profile set up
- An existing EC2 key pair
- An S3 bucket for the Terraform state file

## Usage

```
terraform init
terraform plan -var="my_ip=YOUR_IP_HERE"
terraform apply -var="my_ip=YOUR_IP_HERE"
```

`my_ip` should just be the bare address, e.g. `203.0.113.5`, not a CIDR
block. The security group rule appends `/32` itself.

Terraform prints the site's URL when it's done.

To tear everything down:

```
terraform destroy
```
