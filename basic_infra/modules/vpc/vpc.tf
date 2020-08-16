resource "aws_vpc" "default" {
  cidr_block = var.vpc_block
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_subnet" "public" {
  cidr_block        = var.public_subnet_block
  vpc_id            = aws_vpc.default.id
  availability_zone = var.public_subnet_availability_zone
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table" "nat" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "nat" {
  route_table_id = aws_route_table.nat.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_security_group" "nat" {
  name   = "security group for NAT Access"
  vpc_id = aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "private" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = [aws_subnet.private.cidr_block]
  security_group_id = aws_security_group.nat.id
}

resource "aws_subnet" "private" {
  cidr_block        = var.private_subnet_block
  vpc_id            = aws_vpc.default.id
  availability_zone = var.private_subnet_availability_zone
}