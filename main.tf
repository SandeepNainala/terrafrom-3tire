resource "aws_vpc" "custom_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "custom vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.custom_vpc.id
  availability_zone_zone_id = "us-east-1a"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public-subnet-2" {
  vpc_id     = aws_vpc.custom_vpc.id
  availability_zone_id = "us-east-1b"
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "public-subnet-2"
  }
}
resource "aws_subnet" "private-subnet-1" {
  vpc_id     = aws_vpc.custom_vpc.id
  availability_zone_id = "us-east-1a"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id     = aws_vpc.custom_vpc.id
  availability_zone_id = "us-east-1b"
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "private-subnet-2"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.igw.id
  }
}
  resource "aws_route_table" "private-route-table" {
    vpc_id = aws_vpc.custom_vpc.id

    route {
      cidr_block = "10.0.2.0/24"
      #gateway_id = aws_internet_gateway.NAT-GW.id
    }
  }

  resource "aws_route_table_association" "public-route" {
    subnet_id      = [public-subnet-1,public-subnet-2]
    route_table_id = "public-route-table"
  }

resource "aws_route_table_association" "private-route-table" {
  route_table_id = "private-route-table"
  subnet_id      = [private-subnet-1,private-subnet-2]
  gateway_id     = "NAT-GW.id"
}

resource "aws_nat_gateway" "NAT-GW" {
  allocation_id = aws_eip.custom_eip.id
  connectivity_type = "private"
  subnet_id         = aws_subnet.public-subnet-2.id
}

resource "aws_eip" "custom_eip" {
  vpc = true
}

/*resource "aws_lb" "LB" {
  name               = "LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG.id]
  subnets            = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
}*/

resource "aws_security_group" "custom-sg" {
  name        = "SG"
  description = "Security group for Load balancer"
  vpc_id      = aws_vpc.custom_vpc.id

  tags = {
    Name = "security-group"
  }
}

resource "alb" "ALB-1" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "my-alb"

  load_balancer_type = "application-frontend"

  vpc_id             = "custom_vpc"
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
  security_groups    = [aws_security_group.custom-sg.id]
  internal           = false
  }


resource "alb" "ALB-2" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "my-alb"

  load_balancer_type = "application-backend"

  vpc_id             = "custom_vpc"
  availability_zone_id = ["us-east-1a","us-east-1b"]
  subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
  security_groups    = [aws_security_group.custom-sg.id]
  internal           = false
}
target_groups = [
  {
    name_prefix      = "pref-"
    backend_protocol = "HTTP"
    backend_port     = 80
    target_type      = "instance"
    targets = {
      my_target = {
        target_id = ""
        port = 80
      }
      my_other_target = {
        target_id = "public-subnet-1"
        port = 8080
      }
    }
  }
]

resource "aws_launch_template" "test" {
  name_prefix   = "test"
  image_id      = "ami-03265a0778a880afb"
  instance_type = "t3.micro"
}

resource "aws_autoscaling_group" "custom-as" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.test.id
    version = "$Latest"
  }
}

https_listeners = [
  {
    port               = 443
    protocol           = "HTTPS"
    target_group_index = 0
  }
]

http_tcp_listeners = [
  {
    port               = 80
    protocol           = "HTTP"
    target_group_index = 0
  }
]

tags = {
  Environment = "Dev"
}
