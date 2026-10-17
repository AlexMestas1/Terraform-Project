variable "aws_region" {
  description = "aws region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "named aws cli profile to use"
  type        = string
  default     = "terraform-user"
}

variable "project_name" {
  description = "value of the Project tag put on every resource"
  type        = string
  default     = "terraform-demo"
}

variable "instance_type" {
  description = "ec2 instance type, must be an x86_64 type because the ami lookup is x86_64"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^[a-z0-9-]+\\.[a-z0-9-]+$", var.instance_type))
    error_message = "instance_type should look like t2.micro, m5.large or m7i-flex.large."
  }

  # graviton types (t4g, m6g, c7gn, a1 and so on) are arm64, and launching an
  # x86_64 ami on one fails at apply time with an architecture mismatch
  validation {
    condition     = !can(regex("^([a-z]+[0-9]+g[a-z]*|a1)\\.", var.instance_type))
    error_message = "instance_type looks like an arm (graviton) type, but ec2.tf looks up an x86_64 ami. Pick an x86_64 type or change the ami lookup."
  }
}

variable "key_name" {
  description = "name of an existing ec2 key pair to attach for ssh"
  type        = string
  default     = "myec2key"

  validation {
    condition     = length(trimspace(var.key_name)) > 0
    error_message = "key_name can't be empty, the output ssh command and the instance both use it."
  }
}

variable "http_allowed_cidr" {
  description = "cidr block allowed to reach the website on port 80"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    # cidrnetmask alone also accepts 198.51.100.5/24, which has host bits set.
    # the security group rule only takes the network address (198.51.100.0/24)
    condition     = can(cidrnetmask(var.http_allowed_cidr)) && try(cidrhost(var.http_allowed_cidr, 0) == split("/", var.http_allowed_cidr)[0], false)
    error_message = "http_allowed_cidr must be a valid IPv4 cidr block written as its network address, e.g. 0.0.0.0/0 or 198.51.100.0/24 (not 198.51.100.5/24)."
  }
}

variable "my_ip" {
  description = "my public ip address, for ssh access"
  type        = string

  validation {
    # the regex keeps out a /32 or stray text, cidrhost checks every octet is
    # really 0 to 255. the regex alone let 999.999.999.999 through
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.my_ip)) && can(cidrhost("${var.my_ip}/32", 0))
    error_message = "my_ip must be a plain IPv4 address, e.g. 203.0.113.5 (no /32, ec2.tf already appends that part, and each part must be 0 to 255)."
  }
}
