//Main.tf to create vpc with 2AZs, 3 Subnets (App Layer, Data Layer, Public Layer), Internet Gateway, Route Table

/*
Order of execution:

1.  VPC & Networking (VPC, Subnets, IGW, Route Tables)
2.  Security Groups (for ECS, RDS, ALB)
3.  RDS (Database layer) --> Create RDS instance in a private subnet and make sure it's accessible from ECS containers (app layer). This can be done by adding the ECS security group to the RDS security group.
4.  ECS Cluster (App layer)
5.  Application Load Balancer (ALB) (for routing traffic)
6.  ECS Services & Tasks (App layer containers)
7.  Auto Scaling (if needed for ECS)
8.  Lambda Functions (if needed for serverless backend)
9.  API Gateway (to expose Lambda functions)
10. IAM Roles & Policies (for resource access)
11. Monitoring, Logging, and Backup (CloudWatch, etc.)

Step 1: Create VPC, Subnets, and Route Tables.
Step 2: Create Security Groups for ECS, RDS, ALB, etc.
Step 3: Provision RDS instance in a private subnet.
Step 4: Provision ECS Cluster and ECS Task Definitions (with containers for your app).
Step 5: Provision the ALB (with target group and listener rules).
Step 6: Attach ECS services to the ALB and configure Auto Scaling if needed.
Step 7: Provision Lambda functions and API Gateway.
Step 8: Set up IAM roles for ECS, Lambda, and other resources.
Step 9: Configure monitoring and logging.

*/



// -------------------------- VPC SETUP START -------------------------- //

# Provider
//Main.tf to create vpc with 2AZs, 3 Subnets (App Layer, Data Layer, Public Layer), Internet Gateway, Route Table

/*
Order of execution:

1.  VPC & Networking (VPC, Subnets, IGW, Route Tables)
2.  Security Groups (for ECS, RDS, ALB)
3.  RDS (Database layer) --> Create RDS instance in a private subnet and make sure it's accessible from ECS containers (app layer). This can be done by adding the ECS security group to the RDS security group.
4.  ECS Cluster (App layer)
5.  Application Load Balancer (ALB) (for routing traffic)
6.  ECS Services & Tasks (App layer containers)
7.  Auto Scaling (if needed for ECS)
8.  Lambda Functions (if needed for serverless backend)
9.  API Gateway (to expose Lambda functions)
10. IAM Roles & Policies (for resource access)
11. Monitoring, Logging, and Backup (CloudWatch, etc.)

Step 1: Create VPC, Subnets, and Route Tables.
Step 2: Create Security Groups for ECS, RDS, ALB, etc.
Step 3: Provision RDS instance in a private subnet.
Step 4: Provision ECS Cluster and ECS Task Definitions (with containers for your app).
Step 5: Provision the ALB (with target group and listener rules).
Step 6: Attach ECS services to the ALB and configure Auto Scaling if needed.
Step 7: Provision Lambda functions and API Gateway.
Step 8: Set up IAM roles for ECS, Lambda, and other resources.
Step 9: Configure monitoring and logging.

*/



// -------------------------- VPC SETUP START -------------------------- //

provider "aws" {
    region = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

// Create a VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true 

    tags = {
      Name = "Cloud-Project-VPC"
    }
}

// Create subnets

//Public Subnet for load balancers
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    count = 2 //2 subnets in 2 AZs
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = ["us-east-1a", "us-east-1b"][count.index]
    map_public_ip_on_launch = true

    tags = {
      Name = "public-subnet-${count.index + 1}"
    }
}


//Private Subnet for application servers (app layer, ecs)
resource "aws_subnet" "private" {
  count = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = ["us-east-1a", "us-east-1b"][count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

//Add more subnets if you need more availability zones

// Create an Internet Gateway
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Cloud-Project-IGW"
  }
}

// Create a Route Table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-route-table"
  }
}

// Create a Route
resource "aws_route" "internet_access" { //allows traffic to go out to the internet
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0" //all traffic
  gateway_id = aws_internet_gateway.internet_gw.id
}

// Associate the Route Table with the Subnet
resource "aws_route_table_association" "public_subnets_association" {
    count = 2
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public_route_table.id
}

// Create Route Table for private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

// Associate the Route Table with the Subnet
resource "aws_route_table_association" "private_subnets_association" {
  count = 2
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

//create a vpc endpoint for ECS to access ECR 
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.ecs_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.ecs_sg.id]
  private_dns_enabled = true
}

//s3 endpoint becuase ecr uses s3
resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
#   subnet_ids = aws_subnet.private[*].id
  route_table_ids = [aws_route_table.private_route_table.id]
}


// -------------------------- VPC SETUP END -------------------------- //


// -------------------------- SECURITY GROUPS SETUP START -------------------------- //

//Security Group for ECS (App Layer) to allow incoming traffic from ALB and outgoing traffic to RDS
// Create ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"

}
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id

  // Allow inbound traffic from ALB
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow outbound traffic to ALB
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow outbound traffic to ECR VPC endpoint

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}



//Security Group for ALB (Public Layer) to allow incoming traffic from the internet and outgoing traffic to ECS
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  // Allow inbound traffic from the internet
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow outbound traffic to ECS 
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = [aws_security_group.ecs_sg.id] //allow traffic to ECS security group
  }

  tags = {
    Name = "alb-sg"
  }
}
// -------------------------- SECURITY GROUPS SETUP END -------------------------- //

// -------------------------- ALB SETUP START -------------------------- //
// Create ALB
resource "aws_lb" "main" {
  name = "ecs-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = aws_subnet.public[*].id

}

// Create ALB Listener 
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
}

// Create ALB Target Group so that ALB can route traffic to ECS services
resource "aws_lb_target_group" "ecs_target_group" {
  name = "ecs-target-group"
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

//-------------------------- ALB SETUP END -------------------------- //


// -------------------------- ECS SETUP START -------------------------- //
// Create ECS Task Definition
resource "aws_ecs_task_definition" "react_app_task_definition" {
  family = "react-app-task"
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name = "ecr-react-app"
    image = "241533118783.dkr.ecr.us-east-1.amazonaws.com/ecr-react-app:latest" //use the ECR repo url here once image is pushed
    memory = 1024 //1GB
    cpu = 512 //0.5 vCPU
    portMappings = [{
      containerPort = 80 // React app runs on port 80 with nginx. Provide the nginx congif in docker img
      hostPort = 80 // ALB forwards to port 80
    }]
  }])

  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"
}

// Create ECS Service
resource "aws_ecs_service" "react_app_service" {
  name = "react-app-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.react_app_task_definition.arn
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name = "ecr-react-app"
    container_port = 80
  }

  depends_on = [ aws_lb_listener.http_listener ] //wait for ALB listener to be created before creating ECS service
}


//-------------------------- ECS SETUP END -------------------------- //


// -------------------------- IAM SETUP START -------------------------- //

//IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name = "EcsTaskExecutionPolicy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Grant permissions for ECS tasks to access a specific S3 bucket
      {
        Action = "s3:GetObject"
        Effect = "Allow"
        Resource = "arn:aws:s3:::prod-region-starport-layer-bucket/*"
      },
      # (Optional) Other permissions like ECR access can be added here if needed
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
  role = aws_iam_role.ecs_task_execution_role.name
}


//-------------------------- IAM SETUP END -------------------------- //

// -------------------------- MONITORING, LOGGING, BACKUP SETUP START -------------------------- //
//-------------------------- MONITORING, LOGGING, BACKUP SETUP END -------------------------- //

// -------------------------- RDS SETUP START -------------------------- //

//make rds in private_subnet_2 and allow private_subnet_1 (app layer with ecs) to access it.

//Security Group for RDS (Database Layer)
# resource "aws_security_group" "rds_sg" {
#   vpc_id = aws_vpc.main.id

#   // Inbound rule for private_subnet_1 (app layer)
#   ingress {
#     from_port = 5432 //postgres port
#     to_port = 5432
#     protocol = "tcp"
#     # cidr_blocks = [aws_subnet.private_subnet_1.cidr_block] //should not be needed since security_group below allows traffic from private_subnet_1
#     security_groups = [aws_security_group.ecs_sg.id] //allow traffic from ECS security group
#   }

#   // Outbound rule to allow all traffic
#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  
# }

# // Create RDS instance
# resource "aws_db_instance" "main_db" {
#   engine = "postgres"
#   instance_class = "db.t2.micro"
#   allocated_storage = 20
#   db_subnet_group_name = aws_db_subnet_group.main.name
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   multi_az = false
#   username = "admin"
#   password = "password"
#   db_name = "cloud-db"
#   publicly_accessible = false
#   storage_type = "gp2"
#   skip_final_snapshot = true
# }

# // DB Subnet Group for RDS. This is needed to place the RDS instance in the private subnet.
# resource "aws_db_subnet_group" "main" {
#   name = "main-db-subnet-group"
#   subnet_ids = [aws_subnet.private_subnet_2.id]

#   tags = {
#     Name = "main-db-subnet-group"
#   }
# }

//-------------------------- RDS SETUP END -------------------------- //