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

run "user_data_is_safe_to_run_on_linux" {
  command = plan

  assert {
    condition     = !strcontains(aws_instance.ec2_instance.user_data, "\r")
    error_message = "install_website.sh has windows line endings, the shebang would fail on the instance"
  }

  assert {
    condition     = startswith(aws_instance.ec2_instance.user_data, "#!/bin/bash\n")
    error_message = "install_website.sh should start with a bash shebang"
  }

  assert {
    condition     = aws_instance.ec2_instance.user_data_replace_on_change == true
    error_message = "a changed script should replace the instance, user_data only runs on first boot"
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

# the pattern in my_ip only counted digits, so an address that can't exist got
# past the variable and failed later inside the security group rule, with an
# error that pointed at ec2.tf instead of at my_ip
run "my_ip_rejects_octets_over_255" {
  command = plan

  variables {
    my_ip = "999.999.999.999"
  }

  expect_failures = [var.my_ip]
}

run "my_ip_rejects_a_single_octet_over_255" {
  command = plan

  variables {
    my_ip = "203.0.113.256"
  }

  expect_failures = [var.my_ip]
}

# cidrnetmask accepts a block with host bits set, but the security group rule
# wants the network address, so this used to fail late with the same kind of
# misleading error
run "http_cidr_rejects_host_bits" {
  command = plan

  variables {
    http_allowed_cidr = "198.51.100.5/24"
  }

  expect_failures = [var.http_allowed_cidr]
}

run "http_cidr_accepts_a_network_address" {
  command = plan

  variables {
    http_allowed_cidr = "198.51.100.0/24"
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.http.cidr_ipv4 == "198.51.100.0/24"
    error_message = "a valid network address was rejected or changed"
  }
}

run "http_cidr_rejects_junk" {
  command = plan

  variables {
    http_allowed_cidr = "everyone"
  }

  expect_failures = [var.http_allowed_cidr]
}

run "x86_instance_types_are_accepted" {
  command = plan

  variables {
    instance_type = "t3.small"
  }

  assert {
    condition     = aws_instance.ec2_instance.instance_type == "t3.small"
    error_message = "instance_type was ignored"
  }
}

run "graviton_instance_type_is_rejected" {
  command = plan

  variables {
    instance_type = "t4g.micro"
  }

  expect_failures = [var.instance_type]
}

run "other_graviton_families_are_rejected" {
  command = plan

  variables {
    instance_type = "c7gn.large"
  }

  expect_failures = [var.instance_type]
}

run "instance_type_rejects_junk" {
  command = plan

  variables {
    instance_type = "bigger please"
  }

  expect_failures = [var.instance_type]
}

run "key_name_cannot_be_blank" {
  command = plan

  variables {
    key_name = "  "
  }

  expect_failures = [var.key_name]
}

# my first version of the instance_type check had no hyphen in the pattern and
# rejected real types like this one
run "instance_types_with_a_hyphen_are_accepted" {
  command = plan

  variables {
    instance_type = "m7i-flex.large"
  }

  assert {
    condition     = aws_instance.ec2_instance.instance_type == "m7i-flex.large"
    error_message = "a valid hyphenated instance type was rejected"
  }
}
