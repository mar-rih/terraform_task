remote_state {
  backend = "s3"
  config = {
    bucket         = "tf-course-20201104-marwanalrihawi"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    dynamodb_table = "prod_web_state_lck"
    role_arn       = "arn:aws:iam::211590417027:role/SRE"
    region         = "us-east-2"
  }
}

iam_role = "arn:aws:iam::211590417027:role/SRE"