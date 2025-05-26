module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.32"

  cluster_endpoint_public_access = true
  enable_cluster_creator_admin = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      desired_size   = var.desired_capacity
      min_size       = 1
      max_size       = 5
    }
  }

    eks_access_entries = {
    ecs-workshop-user = {
      kubernetes_groups = ["system:masters"]
      principal_arn     = "arn:aws:iam::233736837022:user/ecs-workshop-user"
      policy_associations = []
    }
    gha-eks-admin = {
      kubernetes_groups = ["system:masters"]
      principal_arn     = "arn:aws:iam::233736837022:role/gha-eks-admin"
      policy_associations = []
    }
  }
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

# resource "kubernetes_cluster_role_binding" "eks_admins" {
#   metadata {
#     name = "eks-admins-binding"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "Group"
#     name      = "eks-admins"
#     api_group = "rbac.authorization.k8s.io"
#   }
# }