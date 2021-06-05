data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "init_wordpress" {
  template = file("./_resources/init-wordpress.sh.tpl")

  vars = {
    wordpress_url      = var.wordpress_url
    wordpress_db       = var.wordpress_database
    wordpress_username = var.wordpress_user
    wordpress_password = var.wordpress_password
  }
}

data "template_cloudinit_config" "init_wordpress" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init-wordpress.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_wordpress.rendered
  }
}

resource "aws_instance" "instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = var.subnet_id
  user_data_base64            = data.template_cloudinit_config.init_wordpress.rendered
  security_groups             = [var.wordpress_security_group]
  key_name                    = var.key_name

  tags = {
    Name = "wordpress"
  }
}
