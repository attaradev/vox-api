locals {
  subnet_az_map = zipmap(var.availability_zones, range(length(var.availability_zones)))
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

resource "aws_subnet" "public" {
  for_each = { for idx in range(length(var.availability_zones)) : idx => {
    az   = var.availability_zones[idx]
    cidr = var.public_subnet_cidrs[idx]
  } }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.value.az}"
    Tier = "public"
  })
}

resource "aws_subnet" "private_app" {
  for_each = { for idx in range(length(var.availability_zones)) : idx => {
    az   = var.availability_zones[idx]
    cidr = var.private_app_subnet_cidrs[idx]
  } }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name}-app-${each.value.az}"
    Tier = "private-app"
  })
}

resource "aws_subnet" "private_data" {
  for_each = { for idx in range(length(var.availability_zones)) : idx => {
    az   = var.availability_zones[idx]
    cidr = var.private_data_subnet_cidrs[idx]
  } }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name}-data-${each.value.az}"
    Tier = "private-data"
  })
}

locals {
  public_subnet_keys        = sort(keys(aws_subnet.public))
  nat_gateway_keys          = var.single_nat_gateway ? slice(local.public_subnet_keys, 0, 1) : local.public_subnet_keys
  nat_gateway_subnet_lookup = { for key in local.nat_gateway_keys : key => aws_subnet.public[key] }
  primary_nat_gateway_key   = local.nat_gateway_keys[0]
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateway_subnet_lookup

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateway_subnet_lookup

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${each.value.availability_zone}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app" {
  for_each = aws_subnet.private_app
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-app-rt-${each.value.availability_zone}"
    Tier = "private-app"
  })
}

resource "aws_route" "private_app_outbound" {
  for_each               = aws_route_table.private_app
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? local.primary_nat_gateway_key : each.key].id
}

resource "aws_route_table_association" "private_app" {
  for_each       = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

resource "aws_route_table" "private_data" {
  for_each = aws_subnet.private_data
  vpc_id   = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-data-rt-${each.value.availability_zone}"
    Tier = "private-data"
  })
}

resource "aws_route" "private_data_outbound" {
  for_each               = aws_route_table.private_data
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.single_nat_gateway ? local.primary_nat_gateway_key : each.key].id
}

resource "aws_route_table_association" "private_data" {
  for_each       = aws_subnet.private_data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_data[each.key].id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name}-flow-logs"
  retention_in_days = var.flow_logs_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.name}-flow-logs"
  })
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.this.id
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination_type     = "cloud-watch-logs"
  max_aggregation_interval = 60
}

resource "aws_security_group" "endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name        = "${var.name}-vpc-endpoints"
  description = "Controls access to interface VPC endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpc-endpoints"
  })
}

resource "aws_vpc_endpoint" "s3" {
  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.public.id],
    [for rt in aws_route_table.private_app : rt.id],
    [for rt in aws_route_table.private_data : rt.id]
  )

  tags = merge(var.tags, {
    Name = "${var.name}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "secrets_manager" {
  count              = var.create_vpc_endpoints ? 1 : 0
  vpc_id             = aws_vpc.this.id
  service_name       = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [for subnet in aws_subnet.private_app : subnet.id]
  security_group_ids = [aws_security_group.endpoints[0].id]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-secretsmanager-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_app : subnet.id]
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-ecr-api-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_app : subnet.id]
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-ecr-dkr-endpoint"
  })
}

resource "aws_vpc_endpoint" "logs" {
  count               = var.create_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_app : subnet.id]
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-logs-endpoint"
  })
}

data "aws_region" "current" {}
