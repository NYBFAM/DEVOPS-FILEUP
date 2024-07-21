# main.tf

variable "region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to use"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to use"
  type        = string
}

variable "sftp_user_name" {
  description = "The name of the SFTP user"
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for the SFTP user"
  type        = string
}