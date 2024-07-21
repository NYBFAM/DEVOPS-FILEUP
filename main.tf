# Provider configuration
provider "aws" {
  region = "us-west-2"
}

# Create an AWS Transfer Family server
resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  endpoint_type          = "VPC"

  endpoint_details {
    vpc_id             = "vpc-0ed60e8064018fabb"      # Replace with your VPC ID
    subnet_ids         = ["subnet-0fc37c5def4bc4346"] # Replace with your subnet ID
    security_group_ids = [aws_security_group.transfer_sg.id]
  }

  tags = {
    Name        = "project-fileup-sftp-server"
    Environment = "test"
  }
}

# Create an EFS file system
resource "aws_efs_file_system" "transfer_efs" {
  creation_token = "project-fileup-efs"

  tags = {
    Name = "project-fileup-efs"
  }
}

# Create a mount target for the EFS file system
resource "aws_efs_mount_target" "efs_mount" {
  file_system_id = aws_efs_file_system.transfer_efs.id
  subnet_id      = "subnet-0fc37c5def4bc4346" # Replace with your subnet ID
}

# Create an IAM role for the Transfer Family server
resource "aws_iam_role" "transfer_role" {
  name = "transfer-family-efs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
}

# Attach necessary policies to the IAM role
resource "aws_iam_role_policy_attachment" "transfer_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
  role       = aws_iam_role.transfer_role.name
}

# Create a user for the SFTP server
resource "aws_transfer_user" "sftp_user_1" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = "testuser"
  role      = aws_iam_role.transfer_role.arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/${aws_efs_file_system.transfer_efs.id}/testuser"
  }
}

# Add SSH key for the user
resource "aws_transfer_ssh_key" "sftp_user_key" {
  server_id = aws_transfer_server.sftp_server.id
  user_name = aws_transfer_user.sftp_user_1.user_name
  body      = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

# Create a security group for the Transfer Family server
resource "aws_security_group" "transfer_sg" {
  name        = "transfer-family-sg"
  description = "Security group for AWS Transfer Family"
  vpc_id      = "vpc-xxxxxxxx" # Replace with your VPC ID

  # Allow inbound SFTP traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this to specific IP ranges
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "transfer-family-sg"
  }
}

# CloudWatch alarm for monitoring
resource "aws_cloudwatch_metric_alarm" "transfer_family_alarm" {
  alarm_name          = "transfer-family-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Transfer"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors AWS Transfer Family errors"
  alarm_actions       = ["arn:aws:sns:us-west-1:058264405340:Transfer-family-alert"] # Replace with your SNS topic ARN

  dimensions = {
    ServerId = aws_transfer_server.sftp_server.id
  }
}