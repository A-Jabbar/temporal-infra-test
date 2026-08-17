resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name        = "Pulsar VPC"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name        = "Pulsar-igw"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnet_cidrs
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name        = "Pulsar-public-${each.key}"
    Tier        = "public"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_subnet" "private" {
  for_each          = var.private_subnet_cidrs
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(var.tags, {
    Name        = "Pulsar-private-${each.key}"
    Tier        = "private"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name        = "Pulsar-nat-eip"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.azs[0]].id

  tags = merge(var.tags, {
    Name        = "Pulsar-nat"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name        = "Pulsar-public-rt"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(var.tags, {
    Name        = "Pulsar-private-rt"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnet_cidrs
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnet_cidrs
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}
