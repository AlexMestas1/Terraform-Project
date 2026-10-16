output "ec2_public_ipv4_url" {
  description = "url of the demo website"
  value       = join("", ["http://", aws_instance.ec2_instance.public_ip])
}

output "ec2_instance_id" {
  description = "id of the ec2 instance, handy for the console or aws cli"
  value       = aws_instance.ec2_instance.id
}

output "security_group_id" {
  description = "id of the security group attached to the instance"
  value       = aws_security_group.ec2_security_group.id
}

output "ec2_ssh_command" {
  description = "ssh command for the instance, assuming the key file is in the current directory"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.ec2_instance.public_ip}"
}
