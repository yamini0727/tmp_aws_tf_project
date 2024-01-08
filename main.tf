resource "aws_ecs_cluster" "cluster1" {
  name = var.cluster_name

  tags = {
    Environment = var.environment
  }

}

resource "aws_s3_bucket" "s3_example" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Environment = var.environment
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = var.sg_name
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb" "alb1" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [aws_subnet.main.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.s3_example.id
    prefix  = "alb1"
    enabled = true
  }

  tags = {
    Environment = var.environment
  }
}


resource "aws_ecs_task_definition" "task1" {
  family                = "task1"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = <<TASK_DEFINITION
    [
      {
        "name": "nginx_container",
        "image": "nginx:latest",
        "cpu": 1024,
        "memory": 2048,
        "essential": true,
        "portMappings": [
          {
            "containerPort" : 80,
            "hostPort"      : 80,
            "protocol": "tcp"
          }
        ]
      }
    ]
  TASK_DEFINITION
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "lb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.main.id
}


resource "aws_ecs_service" "ecs_service" {
  name            = "ecs_service"
  cluster         = aws_ecs_cluster.cluster1.id
  task_definition = aws_ecs_task_definition.task1.arn

  launch_type = "FARGATE"
  network_configuration {
    subnets = [aws_subnet.main.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }


  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    container_name   = "nginx_container"
    container_port   = 80
  }
}

