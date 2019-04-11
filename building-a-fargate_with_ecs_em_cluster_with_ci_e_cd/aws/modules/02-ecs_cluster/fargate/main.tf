### Security 

# ALB Security group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.env}-${var.project_name}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = "${var.vpc_id}"
  
  revoke_rules_on_delete = "true"

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

# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_cluster_sg" {
  name_prefix = "${var.env}-${var.project_name}-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = "${var.vpc_id}"

  revoke_rules_on_delete = "true"

  ingress {
    protocol        = "tcp"
    from_port       = "${var.app_port}"
    to_port         = "${var.app_port}"
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-sg"), var.tags)}"
}


### ALB
resource "aws_alb" "ecs_cluster_alb" {
  name            = "${var.env}-${var.project_name}-alb"
  subnets         = [ "${var.public_subnet1_id}", "${var.public_subnet2_id}" ]
  security_groups = [ "${aws_security_group.alb_sg.id}" ]
  load_balancer_type = "application"

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-alb"), var.tags)}"
}

resource "aws_alb_target_group" "app" {
  name        = "${var.env}-${var.project_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-target-group"), var.tags)}"
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.ecs_cluster_alb.id}"
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy       = "ELBSecurityPolicy-2016-08"
  #certificate_arn  =

  default_action {
    target_group_arn = "${aws_alb_target_group.app.id}"
    type             = "forward"
  }
}

# Create ecs cluster
resource "aws_ecs_cluster" "ecs-cluster" {
  name = "${var.env}-${var.project_name}"

  tags = "${merge(map("Name", "${var.env}-${var.project_name}"), var.tags)}"
}

# Associate policy document with policy 
data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    actions = [
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:DescribeScalingActivities",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:RegisterScalableTarget",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:CreateAutoScalingGroup",
      "autoscaling:CreateLaunchConfiguration",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteLaunchConfiguration",
      "autoscaling:Describe*",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CancelSpotFleetRequests",
      "ec2:CreateInternetGateway",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateVpc",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteSubnet",
      "ec2:DeleteVpc",
      "ec2:Describe*",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:RunInstances",
      "ec2:RequestSpotFleet",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket",
      "ecr:*",
      "ecs:*",
      "ec2:*",
      "cloudwatch:*",
      "logs:*",
      "iam:PassRole",
      "elasticloadbalancing:Describe*",
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoles",
      "iam:ListGroups",
      "iam:ListUsers",
      "iam:ListInstanceProfiles",
    ]
    sid = "1"
    effect = "Allow"
    resources = ["*"]
  }
}

# Create iam policy for ecs_service_role
resource "aws_iam_policy" "ecs_service_policy" {
  name   = "ecs_service_policy_${var.project_name}_${var.env}"
  path   = "/"
  policy = "${data.aws_iam_policy_document.ecs_service_role.json}"
}

# Create ecs service role
resource "aws_iam_role" "ecs_service_role" {
  name                  = "ecs_service_${var.project_name}_${var.env}_role"
  force_detach_policies = "true"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "ecs.amazonaws.com",
          "ecs-tasks.amazonaws.com",
          "codebuild.amazonaws.com",
          "codepipeline.amazonaws.com",
          "ecs.application-autoscaling.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      }
    }
  ]
} 
EOF

  tags = "${merge(map("Name", "${var.env}-${var.project_name}"), var.tags)}"
}

# Attach policy to the service role
resource "aws_iam_policy_attachment" "ecs_service_role_atachment_policy" {
  name = "ecs_service_role_${var.project_name}_policy_attachment"
  roles = ["${aws_iam_role.ecs_service_role.name}"]
  policy_arn = "${aws_iam_policy.ecs_service_policy.arn}"
}