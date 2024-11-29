//Same as reactECS.tf but for FastAPI

resource "aws_ecs_task_definition" "fastapi_task_definition" {
    family = "fastapi-task"
    network_mode = "awsvpc"
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_execution_role.arn
    container_definitions = jsonencode([{
        name = "ecr-fastapi-app"
        image = "241533118783.dkr.ecr.us-east-1.amazonaws.com/fastapiserver:latest"
        # command = ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"] //remove this and check after trying with this
        memory = 1024 //1GB
        cpu = 512 //0.5 vCPU
        portMappings = [{
            containerPort = 80 // FastAPI app runs on port 80 with uvicorn. Provide the uvicorn congif in docker img
            hostPort = 80 // ALB forwards to port 80
        }]
    }])

    requires_compatibilities = ["FARGATE"]
    cpu = "512"
    memory = "1024"
}


resource "aws_ecs_service" "fastapi_service" {
    name = "fastapi-service"
    cluster = aws_ecs_cluster.main.id
    task_definition = aws_ecs_task_definition.fastapi_task_definition.arn
    launch_type = "FARGATE"
    desired_count = 1

    network_configuration {
        subnets = aws_subnet.public[*].id
        security_groups = [aws_security_group.ecs_sg.id]
        assign_public_ip = true
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.fastapi_target_group.arn
        container_name = "ecr-fastapi-app"
        container_port = 80
    }

    depends_on = [ aws_lb_listener.fastapi_http_listener ]
  
}