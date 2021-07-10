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

data "template_file" "init_database" {
  template = file("./_resources/init-database.sh.tpl")

  vars = {
    postgres_username = var.postgres_username
    postgres_password = var.postgres_password
  }
}

data "template_cloudinit_config" "init_database" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init-database.sh"
    content_type = "text/x-shellscript"
    content      = data.template_file.init_database.rendered
  }
}


resource "aws_security_group" "database" {
  name   = "database-sg"
  vpc_id = var.vpc_id

  ingress {
    description      = "Open SSH port"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [var.web_server_security_group]
  }

  ingress {
    description      = "Open Postgres port"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [var.web_server_security_group]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  user_data_base64            = data.template_cloudinit_config.init_database.rendered
  security_groups             = [aws_security_group.database.id]
  key_name                    = var.key_name
}