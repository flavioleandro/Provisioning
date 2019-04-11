# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  
  tags = "${merge(map("Name", "${var.project_name}-${var.env}-vpc"), var.tags)}"
}
##########################
####Public Resources######
##########################
# Create public subnet az1 for VPC
resource "aws_subnet" "public_subnet_az1" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.public_subnet_az1_cidr_block}"
  availability_zone = "${var.availability_zone1}"
  
  tags = "${merge(map("Name", "${var.project_name}-${var.env}-public-subnet-az1"), var.tags)}"
} 

# Create public subnet az2 for VPC
resource "aws_subnet" "public_subnet_az2" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.public_subnet_az2_cidr_block}"
  availability_zone = "${var.availability_zone2}"
  
  tags = "${merge(map("Name", "${var.project_name}-${var.env}-public-subnet-az2"), var.tags)}"
}
# Create Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${merge(map("Name", "${var.project_name}-${var.env}-igw"), var.tags)}"
}
# Create route on IGW on VPC default rtb
resource "aws_default_route_table" "vpc_default_rtb" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
  # Internet gtw route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = "${merge(map("Name", "${var.project_name}-${var.env}-vpc-default-rtb"), var.tags)}"
}
# Associate public subnet az1 with transit VPC rtb az1
resource "aws_route_table_association" "public_subnet_az1_rtb_association" {
  subnet_id      = "${aws_subnet.public_subnet_az1.id}"
  route_table_id = "${aws_default_route_table.vpc_default_rtb.id}"
}

# Associate public subnet az2 with transit VPC default rtb az2
resource "aws_route_table_association" "public_subnet_az2_rtb_association" {
  subnet_id      = "${aws_subnet.public_subnet_az2.id}"
  route_table_id = "${aws_default_route_table.vpc_default_rtb.id}"
}


##Security Group
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.env}-${var.project_name}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-alb-sg"), var.tags)}"
}


#################################
###### Private Resources ########
#################################

# Create private subnet az2 for VPC
resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.private_subnet_az1_cidr_block}"
  availability_zone = "${var.availability_zone1}"

  tags = "${merge(map("Name", "${var.project_name}-${var.env}-private-subnet-az1"), var.tags)}"
}
# Create private subnet az1 for VPC
resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${var.private_subnet_az2_cidr_block}"
  availability_zone = "${var.availability_zone2}"

  tags = "${merge(map("Name", "${var.project_name}-${var.env}-private-subnet-az2"), var.tags)}"
}


# Create Nat Gateway
resource "aws_nat_gateway" "nat_gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = "${merge(map("Name", "${var.project_name}-${var.env}-nat_gw"), var.tags)}"
}

# Create route on NatGW on VPC default rtb
resource "aws_default_route_table" "vpc_default_rtb" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
  # Internet gtw route
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }
  tags = "${merge(map("Name", "${var.project_name}-${var.env}-vpc-default-rtb"), var.tags)}"

}
# Associate private subnet az1 with transit VPC default rtb az1
resource "aws_route_table_association" "private_subnet_az1_rtb_association" {
  subnet_id      = "${aws_subnet.private_subnet_az1.id}"
  route_table_id = "${aws_default_route_table.vpc_default_rtb.id}"
}

# Associate private subnet az2 with transit VPC default rtb az2
resource "aws_route_table_association" "private_subnet_az2_rtb_association" {
  subnet_id      = "${aws_subnet.private_subnet_az2.id}"
  route_table_id = "${aws_default_route_table.vpc_default_rtb.id}"
}
###########################
########## ALB ############
###########################
##Public
resource "aws_alb" "mudeseuplano-alb-pub-dev" {
  name            = "${var.env}-${var.project_name}-alb"
  subnets         = [ "${var.public_subnet1_id}", "${var.public_subnet2_id}" ]
  security_groups = [ "${aws_security_group.alb_sg.id}" ]
  load_balancer_type = "application"

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-alb"), var.tags)}"
}

resource "aws_alb_target_group" "mudeseuplano-tg-pub-dev" {
  name        = "${var.env}-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-target-group"), var.tags)}"
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "ls-mudeseuplano-pub-dev" {
  load_balancer_arn = "${aws_alb.mudeseuplano-alb-pub-mudeseuplano-alb-pub-dev.id}"
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy       = "ELBSecurityPolicy-2016-08"
  #certificate_arn  =

  default_action {
    target_group_arn = "${aws_alb_target_group.mudeseuplano-tg-pub-dev.id}"
    type             = "forward"
  }
}

##Private
resource "aws_alb" "mudeseuplano-alb-priv-dev" {
  name            = "${var.env}-${var.project_name}-alb"
  subnets         = [ "${var.private_subnet1_id}", "${var.private_subnet2_id}" ]
  security_groups = [ "${aws_security_group.alb_sg.id}" ]
  load_balancer_type = "application"

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-alb"), var.tags)}"
}

resource "aws_alb_target_group" "mudeseuplano-tg-priv-dev" {
  name        = "${var.env}-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-target-group"), var.tags)}"
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "ls-mudeseuplano-priv-dev" {
  load_balancer_arn = "${aws_alb.mudeseuplano-alb-priv-dev.id}"
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy       = "ELBSecurityPolicy-2016-08"
  #certificate_arn  =

  default_action {
    target_group_arn = "${aws_alb_target_group.mudeseuplano-tg-priv-dev.id}"
    type             = "forward"
  }
}