# Auto Scaling Group
resource "aws_autoscaling_group" "app_server_asg" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier = data.aws_subnets.my_subnets.ids
  launch_template {
    id      = aws_launch_template.app_server.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "app_2048"
    propagate_at_launch = true
  }
}

data "template_file" "userdata" {
  template = "${file("${path.cwd}/userdata.sh")}"
  vars = {
    MONGO_URI = "mongodb://username:password@${aws_docdb_cluster.mydb.endpoint}:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  }
}

# Launch Template
resource "aws_launch_template" "app_server" {
  name_prefix   = "app-server-"
  image_id      = "ami-04ec97dc75ac850b1"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.mysshkey.key_name
  vpc_security_group_ids = [aws_security_group.app_server.id]
  user_data = base64encode(data.template_file.userdata.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "delete"
    }
  }
}

# Attacher le AutoScalingGroup au Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app_server_asg.name
  lb_target_group_arn = aws_lb_target_group.app_lb_target_group.arn
}

# Scaling Policy (Vise une moyenne de CPU à 20% ou moins)
resource "aws_autoscaling_policy" "cpu_scaling_policy" {
  name                   = "cpu-target-tracking-policy"
  policy_type            = "TargetTrackingScaling"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.app_server_asg.name

  # Target tracking configuration
  target_tracking_configuration {
    target_value = 20.0
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

