variable "name_prefix" {
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

variable "single_nat_gateway" {
  description = "Use a single NAT gateway shared across availability zones"
  type        = bool
  default     = true
}

variable "flow_logs_retention_in_days" {
  description = "Retention period for VPC flow logs"
  type        = number
  default     = 30
}

variable "flow_logs_log_group_name" {
  description = "Optional existing CloudWatch log group name to use for VPC flow logs"
  type        = string
  default     = ""
}

variable "adopt_existing_flow_logs" {
  description = "If true, the module will adopt an existing CloudWatch Logs log group with the generated name instead of creating one. Use only when the log group already exists."
  type        = bool
  default     = false
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

variable "alb_allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_https_listener" {
  description = "Whether to enable HTTPS listener on ALB"
  type        = bool
  default     = false
}

variable "container_port" {
  description = "Port that the ECS tasks expose and ALB targets"
  type        = number
  default     = 80
}
