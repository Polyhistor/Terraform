variable "whitelist" {
  type = list(string)
}
variable "web_image_id" {
  type = string
}
variable "web_instance_type" {
  type = string
}
variable "web_desired_capacity" {
  type = number
}
variable "web_max_size" {
  type = number
}
variable "web_min_size" {
  type = number
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_s3_bucket" "prod_tf_course" {
  bucket = "tf-course-20221111991"
  acl    = "private"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "defaul_az1" {
  availability_zone = "us-west-2a"

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_default_subnet" "defaul_az2" {
  availability_zone = "us-west-2b"

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_security_group" "prod_web" {
  name        = "terra-security-group"
  description = "Allow standard HTTP and HTTPS ports inbound and everything outbound"

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

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_eip" "prod_web" {
  tags = {
    "Terraform" : "true"
  }
}


resource "aws_elb" "prod_web_lb" {
  name            = "prod-web"
  subnets         = [aws_default_subnet.defaul_az1.id, aws_default_subnet.defaul_az2.id]
  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = {
    "Terraform" : "true"
  }
}


resource "aws_launch_template" "prod_web" {
  name_prefix   = "prod-web"
  image_id      = var.web_image_id
  instance_type = var.web_instance_type

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_autoscaling_group" "prod_web" {
  availability_zones = ["us-west-2a", "us-west-2b"]
  #   vpc_zone_identifier = [aws_default_subnet.defaul_az1.id, aws_default_subnet.defaul_az2.id]
  desired_capacity = var.web_desired_capacity
  max_size         = var.web_max_size
  min_size         = var.web_min_size

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web_lb.id
}






