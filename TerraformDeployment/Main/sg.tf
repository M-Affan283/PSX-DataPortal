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
