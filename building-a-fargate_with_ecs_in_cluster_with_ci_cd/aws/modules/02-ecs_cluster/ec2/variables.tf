variable "project_name" { }
variable "env" { }
variable "public_subnet1_id" { }
variable "public_subnet2_id" { }
variable "vpc_id" { }
variable "app_port" { }
variable "ecs_ami" { }
variable "ec2_instance_type" { }
variable tags {
  type = "map"
}