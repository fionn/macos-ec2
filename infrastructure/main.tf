data "aws_ami" "mac1metal" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ec2-macos-12.*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64_mac"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ec2_instance_type_offerings" "mac" {
  filter {
    name   = "instance-type"
    values = ["mac1.metal"]
  }

  location_type = "availability-zone"
}

data "http" "local_ipv4_address" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_vpc" "sandbox" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
}

resource "aws_internet_gateway" "sandbox" {
  vpc_id = aws_vpc.sandbox.id
}

resource "aws_subnet" "sandbox" {
  cidr_block              = cidrsubnet(aws_vpc.sandbox.cidr_block, 8, 0)
  vpc_id                  = aws_vpc.sandbox.id
  map_public_ip_on_launch = true
  availability_zone       = sort(data.aws_ec2_instance_type_offerings.mac.locations)[0]
}

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.sandbox.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sandbox.id
  }
}

resource "aws_route_table_association" "sandbox" {
  subnet_id      = aws_subnet.sandbox.id
  route_table_id = aws_route_table.internet.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  vpc_id      = aws_vpc.sandbox.id
  description = "Allow SSH inbound and all outbound traffic"

  ingress {
    description = "Allow inbound SSH from whitelisted IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = toset(concat(["${chomp(data.http.local_ipv4_address.response_body)}/32"], var.ssh_ingress_cidr_blocks))
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_route53_zone" "primary" {
  name = var.fqdn
}

resource "aws_route53_record" "mac" {
  zone_id = data.aws_route53_zone.primary.id
  name    = "client.${var.id}"
  type    = "A"
  ttl     = 600
  records = [aws_instance.mac.public_ip]
}

resource "aws_ec2_host" "mac" {
  instance_type     = "mac1.metal"
  availability_zone = sort(data.aws_ec2_instance_type_offerings.mac.locations)[0]
}

resource "aws_instance" "mac" {
  ami                    = data.aws_ami.mac1metal.id
  host_id                = aws_ec2_host.mac.id
  instance_type          = "mac1.metal"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id              = aws_subnet.sandbox.id
  user_data              = templatefile("data/mac/init.sh", { password : var.user_password })
  key_name               = aws_key_pair.local_key.key_name

  root_block_device {
    encrypted = true
  }
}

resource "random_id" "key_name" {
  byte_length = 8
  prefix      = "${var.id}-local-key-"
}

resource "aws_key_pair" "local_key" {
  key_name   = random_id.key_name.hex
  public_key = file("~/.ssh/id_ed25519.pub")
}

output "mac_network_data" {
  description = "IP address and DNS name of the server"
  value = {
    "public_ip"   = aws_instance.mac.public_ip
    "public_dns"  = aws_instance.mac.public_dns
    "domain_name" = aws_route53_record.mac.fqdn
  }
}
