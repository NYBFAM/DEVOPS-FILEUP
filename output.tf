# output.tf

output "sftp_server_id" {
  description = "The ID of the SFTP server"
  value       = aws_transfer_server.sftp_server.id
}

output "sftp_server_endpoint" {
  description = "The endpoint of the SFTP server"
  value       = aws_transfer_server.sftp_server.endpoint
}

output "efs_file_system_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.transfer_efs.id
}

output "sftp_user_name" {
  description = "The name of the SFTP user"
  value       = aws_transfer_user.sftp_user_1.user_name
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.transfer_sg.id
}