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

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "my_ip" {
  description = "my public ip address, for ssh access"
  type        = string

  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.my_ip))
    error_message = "my_ip must be a plain IPv4 address, e.g. 203.0.113.5 (no /32, ec2.tf already appends that part)."
  }
}
