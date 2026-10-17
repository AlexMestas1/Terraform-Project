# Terraform-Project

[![Terraform](https://github.com/AlexMestas1/Terraform-Project/actions/workflows/terraform.yml/badge.svg)](https://github.com/AlexMestas1/Terraform-Project/actions/workflows/terraform.yml)

Basic Terraform setup that spins up a single EC2 instance on AWS and
installs a demo website on it.

## What it does

- Uses the account's default VPC and subnet for the region
- Creates a security group allowing HTTP (80) from `http_allowed_cidr`
  (open by default) and SSH (22) from my own IP only. The rules are
  separate `aws_vpc_security_group_*_rule` resources, not inline blocks
- Looks up the latest x86_64 Amazon Linux 2023 AMI through the public SSM
  parameter (Amazon Linux 2 reached end of support in June 2026)
- Launches an EC2 instance with an encrypted root volume and IMDSv2
  required, and runs `install_website.sh` on boot, which installs Apache
  and drops in a small static demo page that shows the instance id and
  availability zone
- Tags every resource with `Project` and `ManagedBy` through the
  provider's `default_tags`

## Variables

| name | default | notes |
| --- | --- | --- |
| `my_ip` | none, required | bare IPv4 address for SSH, no `/32` |
| `key_name` | `myec2key` | existing key pair, can't be blank |
| `instance_type` | `t2.micro` | must be x86_64, arm (Graviton) types are rejected at plan time |
| `http_allowed_cidr` | `0.0.0.0/0` | who can reach port 80 |
| `project_name` | `terraform-demo` | value of the `Project` tag |
| `aws_region` | `us-east-1` | |
| `aws_profile` | `terraform-user` | named AWS CLI profile |

## Outputs

`ec2_public_ipv4_url`, `ec2_ssh_command`, `ec2_instance_id` and
`security_group_id`.

## Requirements

- Terraform 1.5 or newer to plan and apply (CI runs 1.8.5). `terraform test`
  uses mocked providers, which needs 1.7 or newer
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

CI runs `terraform fmt`, `validate`, `terraform test` and `tflint` on every
push. It doesn't run a plan, since that needs AWS credentials.

To tear it down:

```
terraform destroy
```

This removes the instance, the security group and its rules. It does **not**
delete the default VPC and subnet. Terraform only adopts those, and destroy
just drops them from state. They keep the `Name`, `Project` and `ManagedBy`
tags this project put on them, so remove those by hand if you want the
account back exactly as it was.

## Tests

```
terraform test
```

The tests in `tests/main.tftest.hcl` use a mocked AWS provider, so they
need no credentials and never touch the real account. They check that:

- IMDSv2 is required and the root volume is encrypted
- SSH is only open to `my_ip` on port 22, with a `/32`
- `http_allowed_cidr` defaults to open and can be narrowed
- `my_ip`, `http_allowed_cidr`, `instance_type` and `key_name` reject bad
  values, including a CIDR or an octet over 255 in `my_ip`, a block with host
  bits set (`198.51.100.5/24`) in `http_allowed_cidr`, and Graviton instance
  types
- `install_website.sh` has LF line endings and a bash shebang, and a changed
  script replaces the instance (`user_data_replace_on_change`)

## Known limitations

- The S3 backend block sets no `encrypt` and no state locking, so two applies
  at the same time could clobber each other. Native S3 locking
  (`use_lockfile`) needs Terraform 1.10 or newer, and CI and my local copy
  are on 1.8.5. I haven't been able to check the bucket's own versioning and
  encryption settings from the profile I use here, which has no permission to
  read them
- The subnet is the first available AZ in the region. Not every AZ offers
  every instance type. In `us-east-1` the first one offers `t2.micro` and the
  other types I tried, but a different region or a newer type could land in an
  AZ without it, and that only shows up at apply time
- Port 80 is open to the world by default, and all outbound traffic is
  allowed. Both are fine for a throwaway demo and not for anything real
- The instance never picks up newer AMIs on its own (`ignore_changes = [ami]`
  stops the SSM lookup from replacing it). Change the script or run
  `terraform apply -replace=aws_instance.ec2_instance` to get a fresh image

## Troubleshooting

- The instance's boot script logs to `/var/log/user-data.log`. If the site
  doesn't come up, ssh in and read that file first. The script stops at the
  first error and ends by checking Apache answers locally.
- IMDSv2 is required, so a plain `curl http://169.254.169.254/latest/meta-data/`
  returns 401. Get a token first, which `install_website.sh` shows how to do.
- Shell scripts need LF line endings or the shebang breaks on the instance.
  `.gitattributes` pins `*.sh`, `*.tf` and `*.hcl` to LF so a Windows
  checkout doesn't convert them, and a test fails if the script has a CR.
