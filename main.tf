#aws vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

#Subnet1
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet1"
  }
}

#Subnet2
resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet2"
  }
}

#internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "main"
  }
}

#route table
resource "aws_route_table" "myroutetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "myinternetgw"
  }
}

#Subnet1 association
resource "aws_route_table_association" "subnet1association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.myroutetable.id
}

#Subnet2 association
resource "aws_route_table_association" "subnet2association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.myroutetable.id
}

#Security group

resource "aws_security_group" "websg" {

  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#s3bucket
resource "aws_s3_bucket" "example" {
  bucket = "abishek1710s3terraforminfrabucket1wolvie"
  region = "ap-south-1"
}

#iam role for ec2 to access s3
resource "aws_iam_role" "ec2_s3accessrole" {
  name = "s3_access_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

}

#iam policy for s3 access

resource "aws_iam_policy" "s3accessplocy" {
  name        = "s3_policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "Statement1",
        Effect : "Allow",
        Action : [
          "s3:ListBucket",
          "s3:GetObject"
        ],
        Resource : "*"
      }
    ]
  })
}

#iam policy attachment
resource "aws_iam_role_policy_attachment" "s3-attach" {
  role       = aws_iam_role.ec2_s3accessrole.name
  policy_arn = aws_iam_policy.s3accessplocy.arn
}

# 3. Instance profile that wraps the role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "my-ec2-profile"
  role = aws_iam_role.ec2_s3accessrole.name
}

#aws instance 1

resource "aws_instance" "ec21" {
  ami                    = "ami-01a00762f46d584a1"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.websg.id]
  user_data_base64       = base64encode(file("userdata.sh"))
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Ec21"
  }
}

#aws instance 2
resource "aws_instance" "ec22" {
  ami                    = "ami-01a00762f46d584a1"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.websg.id]
  user_data_base64       = base64encode(file("userdata1.sh"))
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Ec22"
  }
}

#Alb
resource "aws_lb" "myalb" {
  name               = "myalb1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  enable_deletion_protection = false
}






#alb target group
resource "aws_lb_target_group" "myalbtg" {
  name     = "myalbtgname"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

#alb listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalbtg.arn
  }
}

#alb target group attachment
resource "aws_lb_target_group_attachment" "tgattachment1" {
  target_group_arn = aws_lb_target_group.myalbtg.arn
  target_id        = aws_instance.ec21.id
  port             = 80
}
#alb target group attachment2
resource "aws_lb_target_group_attachment" "tgattachment2" {
  target_group_arn = aws_lb_target_group.myalbtg.arn
  target_id        = aws_instance.ec22.id
  port             = 80
}



output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}