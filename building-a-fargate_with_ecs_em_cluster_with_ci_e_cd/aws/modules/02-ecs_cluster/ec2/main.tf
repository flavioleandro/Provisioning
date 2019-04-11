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

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
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

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = ["0.0.0.0/0"]
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

# ALB creation

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
# Create intance profile to be used on ec2 instance creation
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs_instance_profile"
  role = "${aws_iam_role.ecs_service_role.name}"
}
# Create ec2 lauch configuration to be used by autoscaling group
resource "aws_launch_configuration" "asg_ec2_launch_configuration" {
  name_prefix                 = "asg_launch_config_${var.project_name}"
  image_id                    = "${var.ecs_ami}"
  instance_type               = "${var.ec2_instance_type}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs_instance_profile.name}"
  security_groups             = ["${aws_security_group.ecs_cluster_sg.id}"]
  associate_public_ip_address = "True"

  depends_on                  = ["aws_efs_mount_target.efs_mount_target1"]
  user_data                   = <<EOF
Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/cloud-boothook; charset="us-ascii"
MIME-Version: 1.0

# Install nfs-utils
cloud-init-per once yum_update yum update -y
cloud-init-per once install_nfs_utils yum install -y nfs-utils 

# Create /efs folder
cloud-init-per once mkdir_efs mkdir -p /home/ec2-user/jenkins

# Mount /efs
cloud-init-per once mount_efs echo -e '${aws_efs_file_system.efs_cluster_ecs.dns_name}:/ /home/ec2-user/jenkins nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0' >> /etc/fstab
mount -a  

--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0

#!/bin/bash
echo ECS_CLUSTER="${aws_ecs_cluster.ecs-cluster.name}" >> /etc/ecs/ecs.config
chown -R ec2-user.ec2-user /home/ec2-user/jenkins
chmod -R 777 /home/ec2-user/jenkins

--==BOUNDARY==--

EOF

  lifecycle {
    create_before_destroy = true
  }
  key_name = "ecs_cluster_node_uswest1"
}
data "null_data_source" "asg-tags" {
  count = "${length(keys(var.tags))}"
  inputs = {
    key                 = "${element(keys(var.tags), count.index)}"
    value               = "${element(values(var.tags), count.index)}"
    propagate_at_launch = "true"
  }
}
# Create appautoscaling for autoscaling group
resource "aws_autoscaling_policy" "asg_autoscaling" {
  name                   = "asg_autoscaling_policy_${var.project_name}"
  autoscaling_group_name = "${aws_autoscaling_group.asg_ec2_instances.name}"
  adjustment_type        = "PercentChangeInCapacity"
  depends_on             = ["aws_autoscaling_group.asg_ec2_instances"]
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  target_value = 70.0
  }
}
# Create autoscaling group for ecs cluster ec2 instances
resource "aws_autoscaling_group" "asg_ec2_instances" {
  name                 = "asg_ec2_instances_${var.project_name}"
  launch_configuration = "${aws_launch_configuration.asg_ec2_launch_configuration.name}"
  vpc_zone_identifier  = [ "${var.public_subnet1_id}", "${var.public_subnet2_id}" ]
  max_size             = 5
  min_size             = 1
  desired_capacity     = 1

  tags = [
    {
      key   = "Name" 
      value = "${var.env}-${var.project_name}" 
      propagate_at_launch = true
    },
    "${data.null_data_source.asg-tags.*.outputs}"
  ]
}
# Create EFS
resource "aws_efs_file_system" "efs_cluster_ecs" {  
  performance_mode = "generalPurpose"
  creation_token   = "${var.project_name}_${var.env}-efs"
  depends_on       = ["aws_ecs_cluster.ecs-cluster"]

  tags = "${merge(map("Name", "${var.env}-${var.project_name}"), var.tags)}"
}

# Mount EFS using the info 
resource "aws_efs_mount_target" "efs_mount_target0" {
  file_system_id  = "${aws_efs_file_system.efs_cluster_ecs.id}"
  subnet_id       = "${var.public_subnet1_id}"
  security_groups = ["${aws_security_group.ecs_cluster_sg.id}"]
  depends_on      = ["aws_efs_file_system.efs_cluster_ecs"]
}

resource "aws_efs_mount_target" "efs_mount_target1" {
  file_system_id  = "${aws_efs_file_system.efs_cluster_ecs.id}"
  subnet_id       = "${var.public_subnet2_id}"
  security_groups = ["${aws_security_group.ecs_cluster_sg.id}"]
  depends_on      = ["aws_efs_file_system.efs_cluster_ecs"]
}