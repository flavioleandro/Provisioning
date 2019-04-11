# task definition
output "task_defintion_arn" {
  value = "${aws_ecs_task_definition.ecs_task_definition.arn}"
}
output "task_definition_revision" {
  value = "${aws_ecs_task_definition.ecs_task_definition.revision}"
}
output "task_definition_family" {
  value = "${aws_ecs_task_definition.ecs_task_definition.family}"
}
# ecr repository
output "ecr_arn" {
  value = "${aws_ecr_repository.ecs_cluster_ecr.arn}"
}
output "ecr_name" {
  value = "${aws_ecr_repository.ecs_cluster_ecr.name}"
}
output "ecr_repository_url" {
  value = "${aws_ecr_repository.ecs_cluster_ecr.repository_url}"
}
# alb listener rule 
output "listener_rule_arn" {
  value = "${aws_alb_listener_rule.listener_rule.arn}"
}
output "listener_rule_id" {
  value = "${aws_alb_listener_rule.listener_rule.id}"
}
# service
output "ecs_service_name" {
  value = "${aws_ecs_service.ecs_service.name}"
}
output "ecs_service_task_definition" {
  value = "${aws_ecs_service.ecs_service.task_definition}"
}
output "ecs_service_cluster" {
  value = "${aws_ecs_service.ecs_service.cluster}"
}
output "ecs_service_id" {
  value = "${aws_ecs_service.ecs_service.id}"
}
output "ecs_service_iam_role" {
  value = "${aws_ecs_service.ecs_service.iam_role}"
}
# appautoscaling target
output "appautoscaling_target_resource_id" {
  value = "${aws_appautoscaling_target.appautoscaling_target.resource_id}"
}
output "appautoscalling_target_role_arn" {
  value = "${aws_appautoscaling_target.appautoscaling_target.role_arn}"
}
# appautoscalling policy
output "appautoscaling_policy_name" {
  value = "${aws_appautoscaling_policy.appautoscaling_policy.name}"
}
output "appautoscaling_policy_arn" {
  value = "${aws_appautoscaling_policy.appautoscaling_policy.arn}"
}
