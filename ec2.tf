# adopt the default vpc, creating it if it does not exist. destroy only drops
# it from state and leaves it (and its tags) in the account
resource "aws_default_vpc" "default_vpc" {

  tags = {
    Name = "default vpc"
  }
}


# use data source to get the availability zones in the region, skipping any
# that are impaired or not opted in
data "aws_availability_zones" "available_zones" {
  state = "available"
}


# adopt the default subnet, same caveat on destroy as the vpc above
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}


# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  tags = {
    Name = "ec2 security group"
  }
}


# the rules are their own resources instead of inline blocks. aws recommends
# this, and inline blocks and separate rules fight over the same group if
# both are used, so the group above deliberately has none
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.ec2_security_group.id
  description       = "http access"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.http_allowed_cidr
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ec2_security_group.id
  description       = "ssh access"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${var.my_ip}/32"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.ec2_security_group.id
  description       = "all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


# amazon linux 2 hit end of support in june 2026, so this looks up the
# current amazon linux 2023 ami through the public ssm parameter that aws
# keeps pointed at the latest image
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}


# launch the ec2 instance and install website
resource "aws_instance" "ec2_instance" {
  ami                    = nonsensitive(data.aws_ssm_parameter.al2023_ami.value)
  instance_type          = var.instance_type
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = var.key_name
  user_data              = file("install_website.sh")

  # user_data only runs on first boot, so a changed script would otherwise be
  # applied in place and never actually run. replace the instance instead
  user_data_replace_on_change = true

  # require IMDSv2 so the metadata service can't be reached with a plain GET
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  # the ssm parameter moves to a new ami every few weeks, without this an
  # unrelated apply would replace the instance
  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name = "demo web server"
  }
}
