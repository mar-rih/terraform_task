terraform {
  backend "s3" {}
}

provider aws {
  version = "~> 2.0"
  region = "us-east-2"
}

resource "aws_security_group" "prod_web" {
  name        = "prod_web"
  description = "Allow std http and https inbound and outbound"
  vpc_id      = var.vpc_id
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
    cidr_blocks = [var.allowed_source_cidr_blk]
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

  ami           = "ami-0743f105d738afe6a"
  instance_type = "t2.nano"

  vpc_security_group_ids = [aws_security_group.prod_web.id]
  subnet_id              = var.private_subnet_id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "terraform" : "true",
    "marwan" : "training"
  }
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "sec_group_elb"
  description = "Security group for public facing ELBs"
  vpc_id      = var.vpc_id

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

resource "aws_elb" "prod_web"{
  name            = "prod-web"
  instances       = aws_instance.prod_web.*.id
  subnets         = [var.public_subnet_id, var.private_subnet_id]
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
