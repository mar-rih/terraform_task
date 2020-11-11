include {
  path = find_in_parent_folders()
}

dependency vpc {
  config_path = "../vpc"
}

terraform {
  source = "../../../modules/nginx"
}

inputs = {
  vpc_id  = dependency.vpc.outputs.vpc_id
  allowed_source_cidr_blk  = dependency.vpc.outputs.private_subnet_cidr_blk
  private_subnet_id = dependency.vpc.outputs.private_subnet_id
  public_subnet_id = dependency.vpc.outputs.public_subnet_id
}

