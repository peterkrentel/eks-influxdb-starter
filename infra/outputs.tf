output "kubeconfig" {
  description = "Kubeconfig YAML for the EKS cluster"
  value = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name = module.eks.cluster_name
    endpoint     = module.eks.cluster_endpoint
    ca_data      = module.eks.cluster_certificate_authority_data
    token        = "" # or use aws_eks_cluster_auth if needed
  })
  sensitive = true
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
