provider "aws" {
  region = "us-east-1"
  access_key = "AKIA6NG4JHDFRA4ZYJDE"
  secret_key = "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"
}


resource "aws_vpc" "vpc-test" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "Test VPC"
    }
}

resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.vpc-test.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
      Name = "Public Subnet"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = "${aws_vpc.vpc-test.id}"

  tags = {
      Name = "Internet Gateway"
  }
}

resource "aws_route_table" "public-subnet-route-table" {
  vpc_id = "${aws_vpc.vpc-test.id}"

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.internet-gateway.id}"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public-subnet-route-table.id}"
}

resource "aws_security_group" "test-instance-security-group" {
  vpc_id = "${aws_vpc.vpc-test.id}"
  name = "test-instance-sg"
  
  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "test-instance" {
  ami = "ami-062f7200baf2fa504"
  instance_type = "t2.nano"
  associate_public_ip_address = true
  private_ip = "10.0.1.11"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.test-instance-security-group.id}"]
  key_name = "arielly-key"

  tags = {
      Name = "test instance"
  }
}

resource "aws_instance" "bastion" {
  ami = "ami-062f7200baf2fa504"
  instance_type = "t2.nano"
  private_ip = "10.0.1.10"
  subnet_id = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.test-instance-security-group.id}"]
  key_name = "arielly-key"

  tags = {
      Name = "bastion"
  }
}

resource "aws_eip" "bastion-eip" {
  instance = "${aws_instance.bastion.id}"
  vpc = true
}