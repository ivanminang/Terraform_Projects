
output "instance_public_ip" {
  value = aws_instance.linux_server[*].public_ip
}

output "instance_private_ip" {
  value = aws_instance.linux_server[*].private_ip
  
}

output "security_goup_id" {
  value = aws_security_group.project4_sg[*].id
  
}
