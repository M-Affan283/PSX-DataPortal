//Main.tf to create vpc with 2AZs, 3 Subnets (App Layer, Data Layer, Public Layer), Internet Gateway, Route Table

/*
Order of execution:

1.  VPC & Networking (VPC, Subnets, IGW, Route Tables)
2.  Security Groups (for ECS, RDS, ALB)
3.  RDS (Database layer)
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

// Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16" 
    enable_dns_support = true
    enable_dns_hostnames = true 
}

// Create subnets

//Public Subnet for load balancers and bastion hosts
resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

//Private Subnet for application servers (app layer, ecs)
resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1a"
}

//Private Subnet for database servers (data layer, rds)
resource "aws_subnet" "private_subnet_2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1a"
}

//Add more subnets if you need more availability zones

// Create an Internet Gateway
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.main.id
}

// Create a Route Table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
}

// Create a Route
resource "aws_route" "public_internet_route" { //allows traffic to go out to the internet
  route_table_id = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0" //all traffic
  gateway_id = aws_internet_gateway.internet_gw.id
}

// Associate the Route Table with the Subnet
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

// Create Route Table for private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
}

// Associate the Route Table with the Subnet
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

// Associate the Route Table with the Subnet
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}


// -------------------------- VPC SETUP END -------------------------- //

// -------------------------- SECURITY GROUPS SETUP START -------------------------- //
//-------------------------- SECURITY GROUPS SETUP END -------------------------- //

// -------------------------- RDS SETUP START -------------------------- //
//-------------------------- RDS SETUP END -------------------------- //

// -------------------------- ECS SETUP START -------------------------- //
//-------------------------- ECS SETUP END -------------------------- //

// -------------------------- ALB SETUP START -------------------------- //
//-------------------------- ALB SETUP END -------------------------- //

// -------------------------- ECS SERVICES SETUP START -------------------------- //
//-------------------------- ECS SERVICES SETUP END -------------------------- //

// -------------------------- AUTO SCALING SETUP START -------------------------- //
//-------------------------- AUTO SCALING SETUP END -------------------------- //

// -------------------------- LAMBDA SETUP START -------------------------- //
//-------------------------- LAMBDA SETUP END -------------------------- //

// -------------------------- API GATEWAY SETUP START -------------------------- //
//-------------------------- API GATEWAY SETUP END -------------------------- //

// -------------------------- IAM SETUP START -------------------------- //
//-------------------------- IAM SETUP END -------------------------- //

// -------------------------- MONITORING, LOGGING, BACKUP SETUP START -------------------------- //
//-------------------------- MONITORING, LOGGING, BACKUP SETUP END -------------------------- //

