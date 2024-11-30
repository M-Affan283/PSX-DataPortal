// -------------------------- ALB SETUP START -------------------------- //
// Create ALB for react-app
# resource "aws_lb" "main" {
#   name = "ecs-alb"
#   internal = false
#   load_balancer_type = "application"
#   security_groups = [aws_security_group.alb_sg.id]
#   subnets = aws_subnet.public[*].id

# }

# // Create ALB Listener 
# resource "aws_lb_listener" "http_listener" {
#   load_balancer_arn = aws_lb.main.arn
#   port = 80
#   protocol = "HTTP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.ecs_target_group.arn
#   }
# }

# // Create ALB Target Group so that ALB can route traffic to ECS services
# resource "aws_lb_target_group" "ecs_target_group" {
#   name = "ecs-target-group"
#   port = 80
#   protocol = "HTTP"
#   vpc_id = aws_vpc.main.id
#   target_type = "ip" //ip because we are using FARGATE launch type

#   health_check {
#     path                = "/"
#     protocol            = "HTTP"
#     port                = "80"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#   }

# }


//Create ALB for FastAPI app
resource "aws_lb" "fastapi_alb" {
  name = "fastapi-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = aws_subnet.public[*].id

}

// Create ALB Listener for FastAPI app
resource "aws_lb_listener" "fastapi_http_listener" {
  load_balancer_arn = aws_lb.fastapi_alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.fastapi_target_group.arn
  }
}


// Create ALB Target Group for FastAPI app
resource "aws_lb_target_group" "fastapi_target_group" {
  name = "fastapi-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id
  target_type = "ip" //ip because we are using FARGATE launch type

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

}

output "fastapi_alb_dns" {
  value = aws_lb.fastapi_alb.dns_name
  
}
//-------------------------- ALB SETUP END -------------------------- //
