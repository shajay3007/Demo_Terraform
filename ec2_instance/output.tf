#
output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.myec_2[0].public_ip
}
output "instance_public_ip_2" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.myec_2[1].public_ip
}