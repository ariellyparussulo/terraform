provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "arielly-terraform"
    key    = "basic_infra"
    region = "us-east-1"
  }
}

module "vpc" {
  source                           = "./modules/vpc"
  vpc_block                        = "10.0.0.0/16"
  public_subnet_block              = "10.0.0.0/24"
  public_subnet_availability_zone  = "us-east-1a"
  private_subnet_block             = "10.0.1.0/24"
  private_subnet_availability_zone = "us-east-1a"
}

module "instances" {
  source             = "./modules/instances"
  key_name           = "default"
  ami                = "ami-0d57c0143330e1fa7"
  instance_type      = "t2.small"
  subnet_id          = module.vpc.public_subnet
  nat_security_group = module.vpc.nat_security_group
  vpc_id             = module.vpc.vpc_id
}