variable "ssh_key_name" {
  description = "The name of the existing EC2 key pair (without .pem) used for SSH access to EKS worker nodes"
  type        = string
  default     = "tier-1"
}
