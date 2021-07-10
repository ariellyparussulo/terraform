provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "<< bucket >>"
    key    = "base_account"
    region = "us-east-1"
  }
}


module "operations_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"

  name = "operations"

  attach_iam_self_management_policy = true

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]
}

module "cloud_trail_monitoring" {
  source = "./modules/cloudtrail"
  bucket = "<< cloud_trai_bucket >>"
  bucket_prefix = "cloudtrail"
}

module "account_config" {
  source = "./modules/config"
  bucket = "<< config_bucket >>"
  bucket_prefix = "config-logs"
  required_tags = {
    tag1Key = "Name"
  }
  iam_password_policy = {
    MinimumPasswordLength = "64"
    PasswordReusePrevention = "3"
    MaxPasswordAge = "30"
  }
  allowed_amis = {
    amiIds = "ami-0ab4d1e9cf9a1215a,ami-09e67e426f25ce0d7"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "giropops"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true
}

module "web_server" {
  source = "./modules/web_server"
  vpc_id = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnets[0]
  key_name = "default"
  ami_version = "ubuntu-focal-20.04-amd64-server-*"
  http_ipv4_security_group = ["0.0.0.0/0"]
  http_ipv6_security_group = ["::/0"]
  ssh_ipv4_security_group = ["0.0.0.0/0"]
  ssh_ipv6_security_group = ["::/0"]
  instance_type = "t3.micro"
  associate_public_ip_address = true
}

module "database" {
  source = "./modules/database"
  vpc_id = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnets[0]
  key_name = "default"
  web_server_security_group = module.web_server.web_server_security_group
  ami_version = "ubuntu-focal-20.04-amd64-server-*"
  instance_type = "t3.micro"
  postgres_username = var.postgres_username
  postgres_password = var.postgres_password
}