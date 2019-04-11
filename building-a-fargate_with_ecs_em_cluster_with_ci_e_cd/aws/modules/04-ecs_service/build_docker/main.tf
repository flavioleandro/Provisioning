# Create task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = "${var.env}-${var.project_name}-${var.service_name}"

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.env}-${var.project_name}-${var.service_name}-service" ,
    "image": "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.env}-${var.project_name}-${var.service_name}:latest",
    "essential": true,
    "memoryReservation": 64,
    "portMappings": [{
      "containerPort": ${var.container_port},
      "hostPort": ${var.container_port}
    }],
    "entrypoint": ["sh", "-c"],
    "command": ["${var.command}"],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "awslogs-${var.env}-${var.project_name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-create-group": "true",
        "awslogs-stream-prefix": "awslogs"
      }
    }
  }
]
DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  execution_role_arn = "${var.ecs_service_role_arn}"
  cpu = 2048
  memory = 4096
}

# Create ecr repository 
resource "aws_ecr_repository" "ecs_cluster_ecr" {
  name = "${var.env}-${var.project_name}-${var.service_name}"
  depends_on = ["aws_alb_listener_rule.listener_rule"]

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-${var.service_name}"), var.tags)}"
}

resource "aws_alb_target_group" "target_group" {
  name        = "${var.env}-${var.project_name}-${var.service_name}"
  port        = "${var.container_port}"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"
  
  health_check {
    matcher   = "200-299"
    path      = "${var.health_check_path}"
    port      = "${var.container_port}"
    protocol  = "HTTP"
    unhealthy_threshold = 10
  }

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-target-group"), var.tags)}"
}

resource "aws_alb_listener_rule" "listener_rule" {
  depends_on = ["aws_alb_target_group.target_group"]

  action {
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
    type             = "forward"
  }

  condition {
    field  = "host-header"
    values = ["*${var.env}.${var.service_name}.aws.clarowcs.cloud"]
  }
  priority     = "${var.priority}"
  listener_arn = "${var.listener_arn}"
}

# Create service
resource "aws_ecs_service" "ecs_service" {
  name             = "${var.env}-${var.project_name}-${var.service_name}-service"
  cluster          = "${var.cluster_arn}"
  task_definition  = "${aws_ecs_task_definition.ecs_task_definition.arn}"
  desired_count    = "${var.instance_count}"
  launch_type      = "FARGATE"
  depends_on       = ["aws_alb_listener_rule.listener_rule"]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.target_group.arn}"
    container_name   = "${var.env}-${var.project_name}-${var.service_name}-service"
    container_port   = "${var.container_port}"
  }

  network_configuration {
    security_groups  = ["${var.ecs_sg_id}"]
    subnets          = ["${var.public_subnet_az1_id}", "${var.public_subnet_az2_id}"]
    assign_public_ip = "true"
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 400

  tags = "${merge(map("Name", "${var.env}-${var.project_name}-${var.service_name}"), var.tags)}"
}

resource "aws_appautoscaling_target" "appautoscaling_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${var.cluster_name}/${var.env}-${var.project_name}-${var.service_name}-service"
  role_arn           = "${var.ecs_service_role_arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on         = ["aws_ecs_service.ecs_service"]
}

resource "aws_appautoscaling_policy" "appautoscaling_policy" {
  name               = "count_per_target"
  service_namespace  = "${aws_appautoscaling_target.appautoscaling_target.service_namespace}"
  scalable_dimension = "${aws_appautoscaling_target.appautoscaling_target.scalable_dimension}"
  resource_id        = "${aws_appautoscaling_target.appautoscaling_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  depends_on         = ["aws_appautoscaling_target.appautoscaling_target"]

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${var.alb_name}/${aws_alb_target_group.target_group.arn_suffix}"
    }
    
    target_value       = 50
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Create a codebuild project to build the docker image and push to ECR
resource "aws_codebuild_project" "codebuild" {
  name         = "${var.env}-${var.project_name}"
  description  = "Build a docker image and send it to ecr"
  service_role = "${var.ecs_service_role_arn}"
  depends_on   = ["aws_ecr_repository.ecs_cluster_ecr"]

  tags = "${merge(map("Name", "${var.env}-${var.project_name}"), var.tags)}"

  artifacts {
    type     = "S3"
    location = "${var.artifact_store}"
    name     = "ArtifactS3Store"
  }

  environment { 
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:18.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    

    environment_variable { 
      name  = "IMAGE_URI"
      value = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.env}-${var.project_name}-${var.service_name}"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "${var.aws_region}"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "SERVICE_NAME"
      value = "${var.env}-${var.project_name}-${var.service_name}-service"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "IMAGE_DEFINITIONS"
      value = "${var.env}-${var.project_name}-${var.service_name}-service.json"
      type  = "PLAINTEXT"
    }
  }

  source { 
    type      = "S3"
    location  = "claro-artifact-store/artifacts.zip"   
    buildspec = "buildspec.yml"
  }
}
# Create codepipeline
resource "aws_codepipeline" "codepipeline" {
  name       = "${var.env}-${var.project_name}"
  role_arn   = "${var.ecs_service_role_arn}"
  depends_on = ["aws_codebuild_project.codebuild"]

  artifact_store { 
    location = "${var.artifact_store}"
    type     = "S3"
  }

  stage { 
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "S3"
      version  = "1"
      output_artifacts = ["source_artifact"]
    
      configuration = {
        S3Bucket               = "${var.artifact_store}"
        S3ObjectKey            = "${var.artifact_name}"
        # PollForceSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_artifact"]
      output_artifacts = ["build_artifact"]

      configuration = {
        ProjectName = "${aws_codebuild_project.codebuild.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_artifact"]

      configuration = {
        ClusterName = "${var.cluster_name}"
        ServiceName = "${aws_ecs_service.ecs_service.name}"
        FileName    = "${var.env}-${var.project_name}-${var.service_name}-service.json"
      }
    }
  }
}