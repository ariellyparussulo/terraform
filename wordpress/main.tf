provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "business-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "vpc_security_groups" {
  source               = "./modules/security-groups"
  vpc_id               = module.vpc.vpc_id
  cicd_public_subnets = module.vpc.public_subnets_cidr_blocks
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier           = "wordpress"
  engine               = "mysql"
  engine_version       = "5.7.19"
  major_engine_version = "5.7"
  family               = "mysql5.7"
  instance_class       = "db.t2.micro"

  allocated_storage = 5
  name              = "wordpress"
  username          = var.wordpress_user
  password          = var.wordpress_password
  port              = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [module.vpc_security_groups.database]
  subnet_ids             = module.vpc.private_subnets
}

module "wordpress" {
  source                   = "./modules/wordpress"
  wordpress_security_group = module.vpc_security_groups.wordpress_public
  subnet_id                = module.vpc.public_subnets[0]
  key_name                 = "default"
  wordpress_url            = module.rds.db_instance_endpoint
  wordpress_database       = "wordpress"
  wordpress_user           = var.wordpress_user
  wordpress_password       = var.wordpress_password
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"

  domain_name  = "wordpress.arielly.online"
  zone_id = "Z052239835ZN8P4MWPYZS"

  tags = {
    Name = "wordpress.arielly.online"
  }
}


module "alb" {
  source  = "terraform-aws-modules/alb/aws"

  name = "wordpress-alb"

  load_balancer_type = "application"

  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.vpc_security_groups.wordpress_load_balancer]

  target_groups = [
    {
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = [
        {
          target_id = module.wordpress.instance_id
          port = 80
        }
      ]
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"

  zone_name = "arielly.online"

  records = [
    {
      name    = "wordpress"
      type    = "CNAME"
      ttl     = 300
      records = [module.alb.lb_dns_name]
    },
  ]
}