# --- ECS Task Definition ---

resource "aws_ecs_task_definition" "test_task_definition" {
  family                   = "demo-app"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn
  network_mode             = "bridge"
#  cpu                      = 0
#  memory                   = 0

  volume {
    name = "socket_volume"
  }

  container_definitions = jsonencode([
    # django
    {
      name      = "dev-aiad-be-www-django"
      image     = "${aws_ecr_repository.dev-aiad-be-www-django.repository_url}:latest"
      cpu       = 0
      memory    = 410
      essential = true
      #    portMappings = [{ containerPort = 80, hostPort = 80 }],

      environment = [
        { name = "AWS_XRAY_DAEMON_ADDRESS", value = "dev-aiad-be-www-xray:2000" }
      ]
      mount_points = [
        { source_volume = "socket_volume", container_path = "/django", read_only = false }
      ]
      depends_on = [
        { container_name = "dev-aiad-be-www-xray", condition = "START" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "ap-northeast-2"
          "awslogs-group"         = "/ecs/dev-aiad-be-www"
          "awslogs-stream-prefix" = "ecs"
        }
      },
    },
    # nginx
    {
      name         = "dev-aiad-be-www-nginx"
      image        = "${aws_ecr_repository.dev-aiad-be-www-nginx.repository_url}:latest"
      cpu          = 0
      memory       = 310
      essential    = true
      port_mappings   = [
        {
          name          = "dev-aiad-be-www-nginx-80-tcp"
          container_port = 80
          host_port      = 0
          protocol      = "tcp"
        }
      ]
      volumes_from    = [
        {
          source_container = "dev-aiad-be-www-django"
          read_only        = false
        }
      ]
      depends_on = [
        { container_name = "dev-aiad-be-www-django", condition = "START" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "ap-northeast-2"
          "awslogs-group"         = "/ecs/dev-aiad-be-www"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name            = "dev-aiad-be-www-xray"
      image           = "${aws_ecr_repository.dev-aiad-be-www-nginx.repository_url}:latest"
      cpu             = 0
      memory          = 125
      essential       = true
      portMappings    = [
        {
          containerPort = 2000
          hostPort      = 0
          protocol      = "udp"
        }
      ]
      command         = [
        "xray",
        "-n",
        "ap-northeast-2",
        "-t",
        "0.0.0.0:2000",
        "-b",
        "0.0.0.0:2000",
        "--bind",
        "0.0.0.0:2000"
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options   = {
          "awslogs-create-group"   = "true"
          "awslogs-group"          = "/ecs/dev-aiad-be-www"
          "awslogs-region"         = "ap-northeast-2"
          "awslogs-stream-prefix"  = "ecs"
        }
      }
    }
  ])
}