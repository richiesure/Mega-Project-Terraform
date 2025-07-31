output "cluster_id" {
  value = aws_eks_cluster.Richie.id
}

output "node_group_id" {
  value = aws_eks_node_group.Richie.id
}

output "vpc_id" {
  value = aws_vpc.Richie_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.Richie_subnet[*].id
}
