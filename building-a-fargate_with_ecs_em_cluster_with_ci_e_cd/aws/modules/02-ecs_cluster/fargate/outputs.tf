# alb sg
output "alb_sg_name" {
  value = "${aws_security_group.alb_sg.name}"
}

output "alb_sg_id" {
  value = "${aws_security_group.alb_sg.id}"
}
# ecs cluster sg
output "ecs_cluster_sg_name" {
  value = "${aws_security_group.ecs_cluster_sg.name}"
}
output "ecs_cluster_sg_id" {
  value = "${aws_security_group.ecs_cluster_sg.id}"
}
# Application Load Balancer
output "ecs_cluster_alb_name" {
  value = "${aws_alb.ecs_cluster_alb.name}"
}
output "ecs_cluster_alb_id" {
  value = "${aws_alb.ecs_cluster_alb.id}"
}
output "ecs_cluster_alb_arn" {
  value = "${aws_alb.ecs_cluster_alb.arn}"
}
output "ecs_cluster_alb_dns_name" {
  value = "${aws_alb.ecs_cluster_alb.dns_name}"
}
output "ecs_cluster_alb_zone_id" {
  value = "${aws_alb.ecs_cluster_alb.zone_id}"
}
output "ecs_cluster_alb_sgs" {
  value = "${aws_alb.ecs_cluster_alb.security_groups}"
}
output "ecs_cluster_alb_subnets" {
  value = "${aws_alb.ecs_cluster_alb.subnets}"
}
output "ecs_cluster_alb_arn_suffix" {
  value = "${aws_alb.ecs_cluster_alb.arn_suffix}"
}

# alb target group 
output "alb_target_goup_name" {
  value = "${aws_alb_target_group.app.name}"
}
output "alb_target_group_id" {
  value = "${aws_alb_target_group.app.id}"
}
output "alb_target_group_arn" {
  value = "${aws_alb_target_group.app.arn}"
}
output "alb_target_group_arn_suffix" {
  value = "${aws_alb_target_group.app.arn_suffix}"
}
# alb listener
output "alb_listener_arn" {
  value = "${aws_alb_listener.front_end.arn}"
}
output "alb_listener_rule_id" {
  value = "${aws_alb_listener.front_end.id}"
}
# ecs cluster 
output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.ecs-cluster.name}"
}
output "ecs_cluster_id" {
  value = "${aws_ecs_cluster.ecs-cluster.id}"
}
output "ecs_cluster_arn" {
  value = "${aws_ecs_cluster.ecs-cluster.arn}"
}
# ecs_service_role
output "ecs_service_role_name" {
  value = "${aws_iam_role.ecs_service_role.name}"
}
output "ecs_service_role_arn" {
  value = "${aws_iam_role.ecs_service_role.arn}"
}
output "ecs_service_role_id" {
  value = "${aws_iam_role.ecs_service_role.id}"
}
