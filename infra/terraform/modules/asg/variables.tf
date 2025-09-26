variable "sg_name" {
  description = "Name of the security group"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "List of allowed CIDR blocks for ingress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change to your trusted CIDRs for production
}
