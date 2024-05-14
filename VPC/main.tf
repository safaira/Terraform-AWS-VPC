
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "First_VPC"
  }
}

# subnet
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"         #   map_public_ip_on_launch = "true"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Subnet-1a"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"         #   map_public_ip_on_launch = "true"
  map_public_ip_on_launch = "true"
  
  tags = {
    Name = "Subnet-2b"
  }
}
# internet_gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
}

# route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# route table association

resource "aws_route_table_association" "rt1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt.id
}

# security_group
resource "aws_security_group" "sg" {
  name        = "SG"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  tags = {
    Name = "SG-1"
  }
}

resource "aws_s3_bucket" "s3" {
  bucket = "terra-pro-san"
}

# instances
resource "aws_instance" "terra-1" {
  ami                    = "ami-0287a05f0ef0e9d9a"
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.subnet1.id
  user_data              = base64encode(file("userdata.sh"))
}

resource "aws_instance" "terra-2" {
  ami                    = "ami-0287a05f0ef0e9d9a"
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.subnet2.id
  user_data              = base64encode(file("userdata1.sh"))
}


# iam role
resource "aws_iam_role" "instance_iamrole" {
  name = "instance_role"
  path = "/"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "IamPassRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  }

resource "aws_iam_role_policy" "role_policy" {
  name = "instance_role_policy"
  role = aws_iam_role.instance_iamrole.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
 policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"s3:GetObject",
				"s3:ListAllMyBuckets"
			],
			"Resource": [ 
      "arn:aws:s3:::terra-pro-san",
      "arn:aws:s3:::terra-pro-san/*" 
      ]
		}
	]
  })
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "instanceprofile"
  role = aws_iam_role.instance_iamrole.name
}


# attch iam_role_policy_attachment
# resource "aws_iam_role_policy_attachment" "role_attachment" {
#   role       = aws_iam_role.instance_iamrole.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }

# resource "aws_s3_bucket_policy" "terra-pro-san" {
#   bucket = "terra-pro-san"

#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": "*" ,
#         "Action": [
#            "s3:GetObject", 
#            "s3:ListBucket" 
#         ],
#         "Resource": [
#           "arn:aws:s3:::terra-pro-san",
#           "arn:aws:s3:::terra-pro-san/*"
#         ]
#       }
#     ]
#   })
# }

# create load balancer (requires-- target group + target group attachment with instances + listner)
resource "aws_lb" "lb" {
  name               = "LB-T"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "web"
  }
}
#  create target group of load banacer 
resource "aws_lb_target_group" "lb-tg" {
  name     = "tf-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
     path = "/"
     port = "traffic-port" 
     }
}
#  attach target group to the instances
resource "aws_lb_target_group_attachment" "tg-attach-1" {
  target_group_arn = aws_lb_target_group.lb-tg.arn
  target_id        = aws_instance.terra-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg-attach-2" {
  target_group_arn = aws_lb_target_group.lb-tg.arn
  target_id        = aws_instance.terra-2.id
  port             = 80
}

#  listner
resource "aws_lb_listener" "lb_listner" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-tg.arn
  }
}
# TO GET THE LB DNS NAME ON TERMINAL
output "loadbalancerdns" {
  value = aws_lb.lb.dns_name
}


# terraform init
# terraform validate or terraform fmt
# terraform plan 
# terraform apply or terraform apply -auto-approve
# terraform destroy