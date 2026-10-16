# these run with a mocked aws provider, so they need no credentials and
# never touch the real account. run them with: terraform test

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["us-east-1a", "us-east-1b"]
    }
  }
}

override_data {
  target = data.aws_ssm_parameter.al2023_ami
  values = {
    value = "ami-0123456789abcdef0"
  }
}

variables {
  my_ip = "203.0.113.5"
}

run "instance_is_locked_down" {
  command = plan

  assert {
    condition     = aws_instance.ec2_instance.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 should be required on the instance"
  }

  assert {
    condition     = aws_instance.ec2_instance.root_block_device[0].encrypted == true
    error_message = "the root volume should be encrypted"
  }
}

run "ssh_only_from_my_ip" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ssh.cidr_ipv4 == "203.0.113.5/32"
    error_message = "ssh should be limited to my_ip with a /32"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ssh.from_port == 22 && aws_vpc_security_group_ingress_rule.ssh.to_port == 22
    error_message = "the ssh rule should only cover port 22"
  }
}

run "http_defaults_to_open_and_can_be_narrowed" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.http.cidr_ipv4 == "0.0.0.0/0"
    error_message = "http should default to open"
  }
}

run "http_cidr_can_be_overridden" {
  command = plan

  variables {
    http_allowed_cidr = "198.51.100.0/24"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.http.cidr_ipv4 == "198.51.100.0/24"
    error_message = "http_allowed_cidr was ignored"
  }
}

run "my_ip_rejects_a_cidr" {
  command = plan

  variables {
    my_ip = "203.0.113.5/32"
  }

  expect_failures = [var.my_ip]
}

run "my_ip_rejects_junk" {
  command = plan

  variables {
    my_ip = "not-an-ip"
  }

  expect_failures = [var.my_ip]
}

run "http_cidr_rejects_junk" {
  command = plan

  variables {
    http_allowed_cidr = "everyone"
  }

  expect_failures = [var.http_allowed_cidr]
}
