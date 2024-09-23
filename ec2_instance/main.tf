# Create VPC
resource "aws_vpc" "my_vpc" {
 # cidr_block = var.vpc_cidr
  cidr_block = var.vpc_cidr
}

# create subnet
resource "aws_subnet" "Public_subnet1" {
  vpc_id = aws_vpc.my_vpc.id
  #cidr_block = var.pub_subnet_ip
  cidr_block = var.pub_subnet_ip
  availability_zone = var.av_zone
  map_public_ip_on_launch = true
}

resource "aws_subnet" "pub_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
 # cidr_block        = var.pub_subnet_ip_2  # New CIDR block
  cidr_block        = var.pub_subnet_ip_2
  availability_zone = var.av_zone_2        # Different availability zone
  map_public_ip_on_launch = true
}




resource "aws_security_group" "public_sg1" {
  vpc_id = aws_vpc.my_vpc.id

 ingress {
    from_port   = 3000
    to_port     = 10000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


dynamic "ingress" {
    for_each = [ 22, 80, 443, 465, 25, 6443 ]
    content {
        from_port = ingress.value
        to_port = ingress.value
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
}
     

    }

 # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # This allows all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public_sg1"
  }
}




# Internet Gateway creation

resource "aws_internet_gateway" "my_IGW" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    name = "Terraform_IGW"
  }
}
# Create Route Table
resource "aws_route_table" "Terra_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_IGW.id
    }
      tags = {
    Name = "my_route_table"
  }
}



# Associate the Route Table with the Subnet
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.Public_subnet1.id
  route_table_id = aws_route_table.Terra_route_table.id
}

#create instances
 resource "aws_instance" "myec_2" {
  count = 2
  subnet_id = aws_subnet.Public_subnet1.id
  security_groups = [aws_security_group.public_sg1.id]
  instance_type   = var.instance_type
  ami = var.image_id
 key_name = "Devops_key"

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = 10  # Size in GB
    volume_type = "gp2"
  }
     # Shell script provided via user_data
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable httpd 
    sudo systemctl status httpd 
    sudo touch /var/www/html/index.html
    echo "Hello from Terraform EC2" > /var/www/html/index.html
  EOF
 

  tags = {
  name = "ec2_servers"
 }
}

#--------------------------------------------------
# S3 module
#--------------------------------------------------
# Call the S3 module
module "s3_bucket" {
  source      = "./s3_bucket"
   # Change this to a unique name
}
#-----------------------
# Create Target Group
#-----------------------

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "My_Target_Group"
  }
}
#-----------------------
# Attach EC2 instances to Target Group
#-----------------------

resource "aws_lb_target_group_attachment" "my_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.myec_2[count.index].id
  port             = 80
}


# Create Load Balancer (ALB)
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_sg1.id]
  subnets            = [
    aws_subnet.Public_subnet1.id,
    aws_subnet.pub_subnet2.id,
  ]

  enable_deletion_protection = false

  tags = {
    Name = "My_ALB"
  }
}
# Create a listener for the ALB
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

