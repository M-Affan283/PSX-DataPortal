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