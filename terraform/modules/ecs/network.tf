resource "aws_vpc" "main" {
  tags       = var.common_tags
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  tags                    = var.common_tags
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main" {
  tags   = var.common_tags
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  tags   = var.common_tags
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_sg" {
  tags = var.common_tags

  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
