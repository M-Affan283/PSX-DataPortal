# // -------------------------- ECS SETUP START -------------------------- //
# // Create ECS Task Definition
# resource "aws_ecs_task_definition" "react_app_task_definition" {
#   family = "react-app-task"
#   network_mode = "awsvpc"
#   execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
#   container_definitions = jsonencode([{
#     name = "ecr-react-app"
#     image = "241533118783.dkr.ecr.us-east-1.amazonaws.com/reactapp:latest" //use the ECR repo url here once image is pushed
#     memory = 1024 //1GB
#     cpu = 512 //0.5 vCPU
#     portMappings = [{
#       containerPort = 80 // React app runs on port 80 with nginx. Provide the nginx congif in docker img
#       hostPort = 80 // ALB forwards to port 80
#     }]
#   }])

#   requires_compatibilities = ["FARGATE"]
#   cpu = "512"
#   memory = "1024"
# }

# // Create ECS Service
# resource "aws_ecs_service" "react_app_service" {
#   name = "react-app-service"
#   cluster = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.react_app_task_definition.arn
#   launch_type = "FARGATE"
#   desired_count = 1

#   network_configuration {
#     subnets = aws_subnet.private[*].id
#     security_groups = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.ecs_target_group.arn
#     container_name = "ecr-react-app"
#     container_port = 80
#   }

#   depends_on = [ aws_lb_listener.http_listener ]
# }