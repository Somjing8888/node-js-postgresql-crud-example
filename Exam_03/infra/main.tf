provider "aws" {
  region = var.ap-southeast-1
  access_key = xxxxx
  secret_key = xxxxx
}

# สร้าง VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

# สร้าง Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# สร้าง Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.ap-southeast-1}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.ap-southeast-1}a"
  tags = {
    Name = "private_subnet"
  }
}

# สร้าง Route Tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
}

# Associate Subnets with Route Tables
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

# สร้าง Security Groups
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow inbound traffic to EKS cluster
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic from EKS cluster
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks_security_group"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.my_vpc.id

  # Allow inbound traffic to RDS from EKS
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_sg.id]
  }

  # Allow outbound traffic from RDS
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds_security_group"
  }
}

# สร้าง DB Subnet Group
resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my_db_subnet_group"
  subnet_ids = [aws_subnet.private_subnet.id]
}

# สร้าง PostgreSQL RDS database
resource "aws_db_instance" "my_rds_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "12.5"
  instance_class       = "db.t3.micro"
  name                 = "my_rds_db"
  username             = "admin"
  password             = "test12345"
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
}

# สร้าง IAM Role สำหรับ EKS Cluster
resource "aws_iam_role" "eks_role" {
  name               = "eks-cluster-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "eks-cluster-role"
  }
}

#สร้าง IAM Role สำหรับ Node Group
resource "aws_iam_role" "eks_node_role" {
  name               = "eks-node-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "eks-node-role"
  }
}

# สร้าง EKS Cluster
resource "aws_eks_cluster" "my_eks_cluster" {
  name     = "my_eks_cluster"
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.29" # กำหนดเวอร์ชันของ EKS cluster เป็น 1.29
  vpc_config {
    subnet_ids         = [aws_subnet.public_subnet.id]
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}


# สร้าง Node Group
resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_eks_cluster.name
  node_group_name = "my_node_group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.public_subnet.id]
  instance_type   = "t3.xlarge"
  disk_size       = 50
}

# ตรวจสอบว่าข้อมูล
output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

output "rds_endpoint" {
  value = aws_db_instance.my_rds_instance.endpoint
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.my_eks_cluster.endpoint
}
