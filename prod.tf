provider "aws" {
   region = "us-east-2"
   
   assume_role {
    role_arn    = "arn:aws:iam::211590417027:role/SRE"  
  }
}

resource "aws_s3_bucket" "prod_tf_course"{
    bucket = "tf-course-20201104-marwanalrihawi"
    acl    = "private"
    tags = {
      "marwan" : "training"
    }
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "prod_web"{
   name  = "prod_web"
   description = "Allow std http and https inbound and evethinh outbound"
  
   ingress {
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
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

   vpc_security_group_ids = [
      aws_security_group.prod_web.id
   ]


   tags = {
      "terraform" : "true",
      "marwan" : "training"
   }
}

resource "aws_eip_association" "prod_web" {
   instance_id   = aws_instance.prod_web[0].id
   allocation_id = aws_eip.prod_web.id
}

resource "aws_eip" "prod_web" {
    instance = aws_instance.prod_web[0].id
    
    tags = {
      "terraform" : "true",
      "marwan" : "training"
   }   
}



