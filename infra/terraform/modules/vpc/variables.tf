variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "vpc_flow_log_group_name" {
  description = "CloudWatch log group name for VPC flow logs"
  type        = string
  default     = ""
}

variable "vpc_flow_log_role_arn" {
  description = "IAM role ARN for VPC flow logs"
  type        = string
  default     = ""
}
