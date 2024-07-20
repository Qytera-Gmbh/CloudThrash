resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.common_tags
}


resource "aws_subnet" "main" {
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

resource "aws_route_table" "main" {
  tags   = var.common_tags
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
  tags   = var.common_tags
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "amazonaws.com"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags                = var.common_tags
}

resource "aws_vpc_dhcp_options_association" "main" {
  dhcp_options_id = aws_vpc_dhcp_options.main.id
  vpc_id          = aws_vpc.main.id
}
