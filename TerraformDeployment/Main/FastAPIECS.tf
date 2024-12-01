//Same as reactECS.tf but for FastAPI

resource "aws_ecs_task_definition" "fastapi_task_definition" {
    family = "fastapi-task"
    network_mode = "awsvpc"
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_execution_role.arn
    container_definitions = jsonencode([{
        name = "ecr-fastapi-app"
        image = var.fastapi_image
        memory = 1024 //1GB
        cpu = 512 //0.5 vCPU
        portMappings = [{
            containerPort = 80 // FastAPI app runs on port 80 with uvicorn. Provide the uvicorn congif in docker img
            hostPort = 80 // ALB forwards to port 80
        }]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
                "awslogs-group" = aws_cloudwatch_log_group.fastapi_log_group.name
                "awslogs-region" = "us-east-1"
                "awslogs-stream-prefix" = "ecs"
            }
        }
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

//AUto scaling for FastAPI service

resource "aws_appautoscaling_target" "fastapi_service_as_target" {
    max_capacity = 3
    min_capacity = 1
    resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.fastapi_service.name}"
    scalable_dimension = "ecs:service:DesiredCount"
    service_namespace = "ecs"
  
}

//Scale up policy
resource "aws_appautoscaling_policy" "fastapi_service_scaling_policy" {
    name = "fastapi-service-scale-up-policy"
    policy_type = "TargetTrackingScaling" //Scale based on target value
    resource_id = aws_appautoscaling_target.fastapi_service_as_target.resource_id
    scalable_dimension = aws_appautoscaling_target.fastapi_service_as_target.scalable_dimension
    service_namespace = aws_appautoscaling_target.fastapi_service_as_target.service_namespace
  
    target_tracking_scaling_policy_configuration {
        predefined_metric_specification {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = 50.0
        scale_in_cooldown = 60
        scale_out_cooldown = 60
    }
    
  
    depends_on = [aws_appautoscaling_target.fastapi_service_as_target]
}


//CLOUDWATCH + SNS ALARM FOR ANY ERROR IN FASTAPI SERVICE

resource "aws_cloudwatch_log_group" "fastapi_log_group" {
    name = "/aws/ecs/fastapi-service"
    retention_in_days = 7
}

resource "aws_cloudwatch_log_metric_filter" "server_error_filter" {
    name = "FastAPIServerErrorFilter"
    log_group_name = aws_cloudwatch_log_group.fastapi_log_group.name
    pattern = "SERVER ERROR"
    metric_transformation {
        name = "ServerError"
        namespace = "FastAPI/Metrics"
        value = "1"
    }
}

resource "aws_cloudwatch_metric_alarm" "server_error_alarm" {
    alarm_name = "fastapi-server-error-alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = aws_cloudwatch_log_metric_filter.server_error_filter.metric_transformation[0].name
    namespace = aws_cloudwatch_log_metric_filter.server_error_filter.metric_transformation[0].namespace
    period = 60
    statistic = "Sum"
    threshold = 1

    alarm_actions = [aws_sns_topic.fastapi_alerts.arn]
}

resource "aws_sns_topic" "fastapi_alerts" {
    name = "FastAPI-Alert-Topic"
}

resource "aws_sns_topic_subscription" "fastapi_alerts_subscription" {
    topic_arn = aws_sns_topic.fastapi_alerts.arn
    protocol = "email"
    endpoint = var.sns_email
}