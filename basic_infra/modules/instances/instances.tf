resource "aws_instance" "private_instance" {
    ami = var.ami
    instance_type = var.instance_type
    source_dest_check = false
    subnet_id = var.subnet_id
    associate_public_ip_address = false
    vpc_security_group_ids = [var.nat_security_group]
    iam_instance_profile = aws_iam_instance_profile.default.name
}

resource "aws_iam_instance_profile" "default" {
  name = "private_instance_profile"
  role = aws_iam_role.default.name
  path = "/"
}

resource "aws_iam_role" "default" {
  name               = "private_instance_role"
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
  name        = "default_session_manager"
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