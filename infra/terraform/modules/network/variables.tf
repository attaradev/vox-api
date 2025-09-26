variable "name" {
  description = "Prefix used for naming network resources"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to distribute subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "public_subnet_cidrs must contain one CIDR per availability zone"
  }
}

variable "private_app_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets hosting application workloads"
  type        = list(string)

  validation {
    condition     = length(var.private_app_subnet_cidrs) == length(var.availability_zones)
    error_message = "private_app_subnet_cidrs must contain one CIDR per availability zone"
  }
}

variable "private_data_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets hosting data services"
  type        = list(string)

  validation {
    condition     = length(var.private_data_subnet_cidrs) == length(var.availability_zones)
    error_message = "private_data_subnet_cidrs must contain one CIDR per availability zone"
  }
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC flow logs to CloudWatch"
  type        = bool
  default     = true
}

variable "flow_logs_retention_in_days" {
  description = "Retention period for VPC flow logs"
  type        = number
  default     = 30
}

variable "create_vpc_endpoints" {
  description = "Whether to create common VPC interface and gateway endpoints"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}
