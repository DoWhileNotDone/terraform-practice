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

resource "aws_elb" "web" {
    name    = "web"

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

resource "aws_launch_template" "web" {
    name_prefix   = "web"
    image_id      = var.web_image_id
    instance_type = var.web_instance_type
}

resource "aws_autoscaling_group" "web" {
    vpc_zone_identifier = [
        aws_default_subnet.default_az1.id,
        aws_default_subnet.default_az2.id,
    ]

    desired_capacity   = var.web_desired_capacity
    max_size           = var.web_max_size
    min_size           = var.web_min_size

    launch_template {
        id      = aws_launch_template.web.id
        version = "$Latest"
    }

    tag {
       key                 = "Terraform" 
       value               = "true"
       propagate_at_launch = true
    }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
    autoscaling_group_name = aws_autoscaling_group.web.id
    elb                    = aws_elb.web.id
}
