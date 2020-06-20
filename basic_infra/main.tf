provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

terraform {
  backend "s3" {
    bucket = "arielly-terraform"
    key = "basic_infra"
    region = "us-east-1"
  }
}

module "vpc" {
  source = "./modules/vpc"
  vpc_block = "10.0.0.0/16"
  public_subnet_block = "10.0.0.0/24"
  public_subnet_availability_zone = "us-east-1a"
  private_subnet_block = "10.0.1.0/24"
  private_subnet_availability_zone = "us-east-1a"
}

module "instances" {
  source = "./modules/instances"
  ami = "ami-09d95fab7fff3776c"
  instance_type = "t2.micro"
  subnet_id = module.vpc.private_subnet
  nat_security_group = module.vpc.nat_security_group
}