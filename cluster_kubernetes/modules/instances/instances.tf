data "template_file" "install_kubernetes" {
  template = file("${path.module}/kubernetes_install.sh")
}

resource "aws_instance" "master" {
    count = var.instance_master_amount
    ami = var.ami
    key_name = var.key_name
    instance_type = var.instance_type
    source_dest_check = false
    subnet_id = var.subnet_id
    associate_public_ip_address = true
    vpc_security_group_ids = [var.nat_security_group, aws_security_group.allow_all.id]
    iam_instance_profile = aws_iam_instance_profile.default.name
    user_data = data.template_file.install_kubernetes.rendered
    tags = {
      Name = "k8s-master"
    }
}

resource "aws_instance" "workers" {
    count = var.instance_workers_amount
    ami = var.ami
    key_name = var.key_name
    instance_type = var.instance_type
    source_dest_check = false
    subnet_id = var.subnet_id
    associate_public_ip_address = true
    vpc_security_group_ids = [var.nat_security_group, aws_security_group.allow_all.id]
    iam_instance_profile = aws_iam_instance_profile.default.name
    user_data = data.template_file.install_kubernetes.rendered
    tags = {
      Name = "k8s-worker-${count.index}"
    }
}

resource "aws_security_group" "allow_all" {
  name = "open_all_ports"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "default" {
  name = "public_instance_profile"
  role = aws_iam_role.default.name
  path = "/"
}

resource "aws_iam_role" "default" {
  name               = "public_instance_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  path               = "/"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "default" {
  name        = "default_session_manager_policy"
  policy      = data.aws_iam_policy.default.policy
  path        = "/"
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

data "aws_iam_policy" "default" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}