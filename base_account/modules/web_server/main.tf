data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/${var.ami_version}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "init_nginx" {
  template = file("./_resources/init-nginx.sh.tpl")
}

data "template_cloudinit_config" "init_nginx" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init-nginx.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_nginx.rendered
  }
}


resource "aws_security_group" "web_server" {
  name   = "web-server-sg"
  vpc_id = var.vpc_id

  ingress {
    description      = "Open HTTP port"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.http_ipv4_security_group
    ipv6_cidr_blocks = var.http_ipv6_security_group
  }

  ingress {
    description      = "Open SSH port"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.ssh_ipv4_security_group
    ipv6_cidr_blocks = var.ssh_ipv4_security_group
  }

  ingress {
    description      = "Open HTTPS port"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.http_ipv4_security_group
    ipv6_cidr_blocks = var.http_ipv6_security_group
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  associate_public_ip_address = var.associate_public_ip_address
  subnet_id                   = var.public_subnet_id
  user_data_base64            = data.template_cloudinit_config.init_nginx.rendered
  security_groups             = [aws_security_group.web_server.id]
  key_name                    = var.key_name
}