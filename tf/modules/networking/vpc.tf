data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  tags = merge(
    { Project = var.project_prefix, Component = "networking" },
    var.tags
  )

  azs = (
    length(var.az_names) > 0
    ? slice(var.az_names, 0, var.num_azs)
    : slice(data.aws_availability_zones.available.names, 0, var.num_azs)
  )

  # Subnetting: carve /16 into /20s; public [0..], private offset by +8
  public_subnet_cidrs  = [for i in range(var.num_azs) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnet_cidrs = [for i in range(var.num_azs) : cidrsubnet(var.vpc_cidr, 4, i + 8)]
}
# ---------------- VPC ----------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${var.project_prefix}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_prefix}-igw" })
}

# ---------------- Subnets ----------------
resource "aws_subnet" "public" {
  for_each = { for idx, az in local.azs : idx => { az = az, cidr = local.public_subnet_cidrs[idx] } }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project_prefix}-public-${each.key}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = { for idx, az in local.azs : idx => { az = az, cidr = local.private_subnet_cidrs[idx] } }

  vpc_id            = aws_vpc.this.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = merge(local.tags, {
    Name = "${var.project_prefix}-private-${each.key}"
    Tier = "private"
  })
}

# ---------------- NAT (EIP + NAT GW) ----------------
resource "aws_eip" "nat" {
  count      = var.nat_gateway_strategy == "one_per_az" ? var.num_azs : 1
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = merge(local.tags, { Name = "${var.project_prefix}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "nat" {
  count         = var.nat_gateway_strategy == "one_per_az" ? var.num_azs : 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = values(aws_subnet.public)[count.index].id
  tags          = merge(local.tags, { Name = "${var.project_prefix}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.igw]
}

# ---------------- Route Tables ----------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_prefix}-rtb-public" })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route tables (per-AZ or single shared)
resource "aws_route_table" "private" {
  count = var.nat_gateway_strategy == "one_per_az" ? var.num_azs : 1
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project_prefix}-rtb-private-${count.index}" })
}

resource "aws_route" "private_default" {
  count                  = length(aws_route_table.private)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[min(count.index, length(aws_nat_gateway.nat) - 1)].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each  = aws_subnet.private
  subnet_id = each.value.id
  route_table_id = (
    var.nat_gateway_strategy == "one_per_az"
    ? aws_route_table.private[tonumber(each.key)].id
    : aws_route_table.private[0].id
  )
}



# ---------------- Gateway Endpoints (S3 & DynamoDB) ----------------
resource "aws_vpc_endpoint" "s3" {
  count              = var.enable_s3_endpoint ? 1 : 0
  vpc_id             = aws_vpc.this.id
  vpc_endpoint_type  = "Gateway"
  service_name       = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids    = [for rt in aws_route_table.private : rt.id]
  tags               = merge(local.tags, { Name = "${var.project_prefix}-vpce-s3" })
}

resource "aws_vpc_endpoint" "dynamodb" {
  count              = var.enable_dynamodb_endpoint ? 1 : 0
  vpc_id             = aws_vpc.this.id
  vpc_endpoint_type  = "Gateway"
  service_name       = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  route_table_ids    = [for rt in aws_route_table.private : rt.id]
  tags               = merge(local.tags, { Name = "${var.project_prefix}-vpce-dynamodb" })
}


