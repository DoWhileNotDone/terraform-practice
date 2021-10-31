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
        cidr_blocks = var.whitelist
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = var.whitelist
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = var.whitelist
    }

    tags =  {
        "Terraform" = "true"
    }
}

module "prod" {
    source = "./modules/prod"

    web_app              = "prod"
    web_image_id         = var.web_image_id
    web_instance_type    = var.web_instance_type
    web_desired_capacity = var.web_desired_capacity
    web_max_size         = var.web_max_size
    web_min_size         = var.web_min_size
    subnets              = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
    security_groups      = [aws_security_group.web.id]
}
