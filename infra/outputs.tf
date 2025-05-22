output "kubeconfig" {
  description = "Raw kubeconfig file"
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
