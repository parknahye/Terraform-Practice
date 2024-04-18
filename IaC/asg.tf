resource "aws_placement_group" "test" {
  name     = "test"
  strategy = "cluster"
}

resource "aws_launch_template" "ecs_ec2_template" {
  name_prefix            = "demo-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.test_cluster.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

# --- ECS ASG ---

resource "aws_autoscaling_group" "test_asg" {
  name_prefix               = "test_asg"
  vpc_zone_identifier       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  min_size                  = 1
  max_size                  = 1
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.ecs_ec2_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "test_asg"
    propagate_at_launch = true
  }

}