variable "project_name" { }
variable "env" { }
variable "aws_account_id" { } 
variable "ecs_service_role_arn" { }
variable "instance_count" { }
variable "service_name" { }
variable "vpc_id" { }
variable "alb_arn" { }
variable "listener_arn" { }
variable "cluster_arn" { }
variable "private_subnet1_id" { }
variable "private_subnet2_id" { }
variable "ecs_sg_id" { }
variable "cluster_name" { }
variable "target_group_name" { }
variable "alb_name" { }
variable "health_check_path" { }
variable "container_port" { }
variable "aws_region" { }
variable "priority" { }
variable "command" { }
variable "tags" {
  type = "map"
}
variable "artifact_store" { }

