
output "instance_public_ip" {
  value = aws_instance.project1_instance.public_ip
}

output "instance_private_ip" {
  value = aws_instance.project1_instance.private_ip
  
}

output "security_goup_id" {
  value = aws_security_group.project1_sg.id
  
}
