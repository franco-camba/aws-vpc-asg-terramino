provider "aws" {
  region = "us-east-2" # Prod is in Ireland

  default_tags {
    tags = {
      workspace = "terramino-app"
    }
  }
}

data "tfe_outputs" "vpc" {
  organization = "fcamba-org"
  workspace = "aws-vpc-Dev"
}

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_configuration" "terramino" {
  name_prefix     = "terramino-"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.small"
  user_data       = file("${path.module}/user-data.sh")
  security_groups = [aws_security_group.terramino_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "terramino" {
  name                 = "terramino"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.terramino.name
  vpc_zone_identifier  = data.tfe_outputs.vpc.values.public_subnets
  health_check_type    = "ELB"
  target_group_arns = [
    aws_lb_target_group.terramino.arn
  ]

  tag {
    key                 = "Name"
    value               = "Terraform Stacks - Terramino"
    propagate_at_launch = true
  }
}

resource "aws_lb" "terramino" {
  name               = "terramino-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terramino_lb.id]
  subnets            = data.tfe_outputs.vpc.values.public_subnets
}

resource "aws_lb_listener" "terramino" {
  load_balancer_arn = aws_lb.terramino.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terramino.arn
  }
}

#test

resource "aws_lb_target_group" "terramino" {
  name     = "terramino"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.tfe_outputs.vpc.values.vpc_id
}

resource "aws_security_group" "terramino_instance" {
  name = "terramino-instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.terramino_lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id   = data.tfe_outputs.vpc.values.vpc_id
}

resource "aws_security_group" "terramino_lb" {
  name = "terramino-lb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id   = data.tfe_outputs.vpc.values.vpc_id
}

output "application_endpoint" {
  value = "http://${aws_lb.terramino.dns_name}/index.php"
}
