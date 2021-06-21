provider "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {}
data "aws_ami" "ami_id" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

output "ubuntu_ou" {
  value = data.aws_ami.ami_id.id
}

output "ubuntu1" {
  value = data.aws_ami.ami_id.name
}
#-----------------------------------------------

resource "aws_security_group" "ASG" {
  name = "Dynamic Security Group"

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic Security Group"
    Owner = "Kolodii Mykhailo"
  }
}

resource "aws_launch_configuration" "LC" {
  name_prefix     = "WebServer-Highly-Available-LC-"
  image_id        = data.aws_ami.ami_id.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.ASG.id]
  user_data       = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

#-----------------------------------------------------------------

resource "aws_autoscaling_group" "ASG" {
  name                 = "ASG-${aws_launch_configuration.LC.name}"
  launch_configuration = aws_launch_configuration.LC.name
  min_size             = 2
  max_size             = 4
  min_elb_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.LB.name]

  dynamic "tag" {
    for_each = {
      Name   = "WebServer in ASG"
      Owner  = "Mykhailo Kolodii"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "LB" {
  name               = "WebServer-LB"
  availability_zones = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  security_groups    = [aws_security_group.ASG.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "My_web_server"
  }
}


resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}

#--------------------------------------------------
output "web_loadbalancer_url" {
  value = aws_elb.LB.dns_name
}
