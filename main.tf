provider "aws" {
    profile = "default"
}

resource "aws_s3_bucket" "tf_course" {
    bucket = "davegthemighty-s3-bucket"
    acl    = "private"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
    availability_zone = "eu-west-2a"

    tags =  {
        "Terraform" = "true"
    }
}

resource "aws_default_subnet" "default_az2" {
    availability_zone = "eu-west-2b"

    tags =  {
        "Terraform" = "true"
    }
}

resource "aws_security_group" "web" {
    name        = "web"
    description = "Allow standard http/https inbound and all outbound"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]        
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [
            "0.0.0.0/0"
        ]        
    }

    tags =  {
        "Terraform" = "true"
    }
}

resource "aws_instance" "web" {
  count         = 2

  ami           = "ami-0c52c335f3334c594"
  instance_type = "t2.nano"

  vpc_security_group_ids = [
    aws_security_group.web.id
  ] 

  tags = {
    "Name"      = "DavegExampleAppServerInstance"
    "Terraform" = "true"
  }
}

resource "aws_eip_association" "web" {
    instance_id   = aws_instance.web[0].id
    allocation_id = aws_eip.web.id
}

resource "aws_eip" "web" {
    tags =  {
        "Terraform" = "true"
    }
}

resource "aws_elb" "web" {
    name      = "web"
    instances = aws_instance.web[*].id

    subnets = [
        aws_default_subnet.default_az1.id,
        aws_default_subnet.default_az2.id,
    ]

    security_groups = [
        aws_security_group.web.id
    ]

    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }

    tags =  {
        "Terraform" = "true"
    }
}