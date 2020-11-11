provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" { }
}

output "vpc_id" {
  value = aws_vpc.prod_web.id
}

output "private_subnet_cidr_blk" {
  value = aws_subnet.private.cidr_block
}
output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "prod_web_state_lck" {
  name = "prod_web_state_lck"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "terraform" : "true",
    "marwan" : "training"
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
  #map_public_ip_on_launch = true
}

