# Terraform-Project

Basic Terraform setup that spins up a single EC2 instance on AWS and
installs a demo website on it.

## What it does

- Uses the account's default VPC and subnet for the region
- Creates a security group allowing HTTP (80) from anywhere and SSH (22)
  from my own IP only
- Looks up the latest Amazon Linux 2 AMI
- Launches an EC2 instance and runs `install_techmax.sh` on boot, which
  installs Apache and pulls down a demo site template

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

Terraform prints the site's URL when it's done.

To tear everything down:

```
terraform destroy
```
