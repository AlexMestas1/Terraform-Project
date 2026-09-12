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
}
