module "vpc" {
  source = "git::https://github.com/pedrohbortolini/opentofu-aws-labs.git//02-reusable-vpc-module/modules/vpc"

  name            = "prod"
  cidr_block      = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  tags = {
    Environment = "prod"
    Project     = "webapp"
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  vpc_id      = module.vpc.vpc_id
  description = "Allow HTTP from internet"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_ec2" {
  name   = "app-ec2-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis" {
  name   = "redis-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# 3. ALB & Target Group & Listener

resource "aws_lb" "app" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets_ids
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path = "/"
  }

}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


//resource "aws_lb_listener" "https" {
//  load_balancer_arn = aws_lb.app.arn
// port              = 443
//protocol          = "HTTPS"
//ssl_policy        = "ELBSecurityPolicy-2016-08"
//certificate_arn   = aws_acm_certificate.app.arn

// default_action {
//  type             = "forward"
// target_group_arn = aws_lb_target_group.app_tg.arn
//}
//}


# 4. Launch Template & Auto Scaling Group

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "cw_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    security_groups = [aws_security_group.app_ec2.id]
  }

  user_data = base64encode(file("${path.module}/scripts/user_data.sh"))
}

resource "aws_autoscaling_group" "app_asg" {
  name             = "app-asg"
  max_size         = var.asg_max
  min_size         = var.asg_min
  desired_capacity = var.asg_desired
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = module.vpc.private_subnets_ids
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "target_cpu" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 45.0
  }
}


/* ONLY USE IF WANT TO CREATE A CLOUDWATCH ALARM FOR HIGH CPU USAGE 
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.target_cpu.arn]
} */

##############################################################################
# 5. RDS Setup
##############################################################################
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "rds-subnet-group"
  subnet_ids = module.vpc.private_subnets_ids
}

resource "aws_db_instance" "appdb" {
  identifier             = "appdb"
  engine                 = "postgres"
  instance_class         = var.rds_instance_class
  allocated_storage      = 20
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
}

##############################################################################
# 6. Redis (ElastiCache) Setup
##############################################################################
resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "redis-subnet-group"
  subnet_ids = module.vpc.private_subnets_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "app-redis"
  description = "redis for app"
  node_type                     = var.redis_node_type
  num_cache_clusters         = 1
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet.name
  security_group_ids            = [aws_security_group.redis.id]
  automatic_failover_enabled    = false
  engine                        = "redis"
  engine_version                = "6.x"
}
