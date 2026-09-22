output "ec2_public_ipv4_url" {
  description = "url of the demo website"
  value       = join("", ["http://", aws_instance.ec2_instance.public_ip])
}

output "ec2_ssh_command" {
  description = "ssh command for the instance, assuming the key file is in the current directory"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.ec2_instance.public_ip}"
}
