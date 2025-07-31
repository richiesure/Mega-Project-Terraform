provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "Richie_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Richie_vpc"
  }
}

resource "aws_subnet" "Richie_subnet" {
  count = 2
  vpc_id                  = aws_vpc.Richie_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.Richie_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["eu-west-2a", "eu-west-2b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "Richie-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "Richie_igw" {
  vpc_id = aws_vpc.Richie_vpc.id

  tags = {
    Name = "Richie-igw"
  }
}

resource "aws_route_table" "Richie_route_table" {
  vpc_id = aws_vpc.Richie_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Richie_igw.id
  }

  tags = {
    Name = "Richie-route-table"
  }
}

resource "aws_route_table_association" "Richie_association" {
  count          = 2
  subnet_id      = aws_subnet.Richie_subnet[count.index].id
  route_table_id = aws_route_table.Richie_route_table.id
}

# Use your existing security group instead of creating new ones
# Cluster and Node Group will use this existing SG
locals {
  existing_sg_id = "sg-067f90f83c62fd777"
}

resource "aws_eks_cluster" "Richie" {
  name     = "Richie-cluster"
  role_arn = aws_iam_role.Richie_cluster_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.Richie_subnet[*].id
    security_group_ids = [local.existing_sg_id]
  }
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.Richie.name
  addon_name   = "aws-ebs-csi-driver"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_node_group" "Richie" {
  cluster_name    = aws_eks_cluster.Richie.name
  node_group_name = "Richie-node-group"
  node_role_arn   = aws_iam_role.devopsshack_node_group_role.arn
  subnet_ids      = aws_subnet.Richie_subnet[*].id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t2.medium"]

  remote_access {
    ec2_ssh_key               = var.ssh_key_name
    source_security_group_ids = [local.existing_sg_id]
  }

  depends_on = [aws_eks_cluster.Richie]
}

# Cluster Role
resource "aws_iam_role" "Richie_cluster_role" {
  name = "Richie-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.Richie_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Node Group Role
resource "aws_iam_role" "devopsshack_node_group_role" {
  name = "devopsshack-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ebs_policy" {
  role       = aws_iam_role.devopsshack_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

