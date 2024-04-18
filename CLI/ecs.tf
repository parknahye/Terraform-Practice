resource "aws_ecs_account_setting_default" "test" {
  name  = "taskLongArnFormat"
  value = "enabled"
}

# capacity provider

resource "aws_ecs_capacity_provider" "test_capacity_provider" {
  name = "test"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.test_asg.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 10
    }
  }
}


# cluster
resource "aws_ecs_cluster" "test_cluster" {
  name = "test_cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# attach capacity provider
resource "aws_ecs_cluster_capacity_providers" "test_ecs_capacity_provider" {
  cluster_name       = aws_ecs_cluster.test_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.test_capacity_provider.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.test_capacity_provider.name
    base              = 1
    weight            = 100
  }
}
# service
# user

resource "aws_ecs_service" "test_ecs_service" {
  name            = "test_ecs_service"
  cluster         = aws_ecs_cluster.test_cluster.id
  task_definition = aws_ecs_task_definition.test_task_definition.arn
  desired_count   = 2

  network_configuration {
    security_groups = [aws_security_group.ecs_task.id]
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.test_capacity_provider.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.test_target_group.arn
    container_name   = "dev-aiad-be-www-nginx"
    container_port   = 80
  }

  depends_on = [
    #aws_lb_target_group.test_target_group,
    aws_ecs_cluster.test_cluster,
    aws_lb_listener.test_elb_listener_http
  ]
}

# --- ECS Service Auto Scaling ---

resource "aws_appautoscaling_target" "ecs_target" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.test_cluster.name}/${aws_ecs_service.test_ecs_service.name}"
  min_capacity       = 2
  max_capacity       = 5
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "ecs_target_memory" {
  name               = "application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}