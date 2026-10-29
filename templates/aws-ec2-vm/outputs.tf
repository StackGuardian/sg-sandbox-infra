output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP address of the instance."
  value       = aws_instance.this.public_ip
}

output "vpc_id" {
  description = "ID of the VPC the instance runs in."
  value       = aws_vpc.this.id
}

output "ssm_connect_command" {
  description = "AWS CLI command that opens a shell on the instance through Session Manager."
  value       = "aws ssm start-session --target ${aws_instance.this.id} --region ${var.region}"
}
