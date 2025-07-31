variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-2"
}

variable "ssh_key_name" {
  description = "The name of the EC2 key pair used for SSH access (without .pem)"
  type        = string
  default     = "tier-1"
}
