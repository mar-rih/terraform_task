provider "aws" {
  region = "us-east-2"

  assume_role {
    role_arn    = "arn:aws:iam::211590417027:role/SRE"
  }
}


resource "aws_vpc" "prod_web" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    "terraform" : "true",
    "marwan" : "training"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.prod_web.id
}

resource "aws_route" "internet_access" {
  route_table_id          = aws_vpc.prod_web.main_route_table_id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.default.id
}

# Create a public subnet to launch our load balancers
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.prod_web.id
  cidr_block              = "10.0.1.0/24" # 10.0.1.0 - 10.0.1.255 (256)
  map_public_ip_on_launch = true
}

# Create a private subnet to launch our backend instances
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.prod_web.id
  cidr_block              = "10.0.16.0/20" # 10.0.16.0 - 10.0.31.255 (4096)
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "sec_group_elb"
  description = "Security group for public facing ELBs"
  vpc_id      = aws_vpc.prod_web.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prod_web"{
  name        = "prod_web"
  description = "Allow std http and https inbound and outbound"
  vpc_id      = aws_vpc.prod_web.id
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow all from private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.private.cidr_block]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "terraform" : "true",
    "marwan" : "training"
  }
}

resource "aws_instance" "prod_web" {
  count = 2

  ami = "ami-0743f105d738afe6a"
  instance_type = "t2.nano"

  vpc_security_group_ids = [aws_security_group.prod_web.id]
  subnet_id = aws_subnet.private.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "terraform" : "true",
    "marwan" : "training"
  }
}

resource "aws_elb" "prod_web"{
  name            = "prod-web"
  instances       = aws_instance.prod_web.*.id
  subnets         = [aws_subnet.public.id, aws_subnet.private.id]
  security_groups = [aws_security_group.elb.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = {
    "terraform" : "true",
    "marwan" : "training"
  }
}


