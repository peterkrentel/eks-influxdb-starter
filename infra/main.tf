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
  version = "~> 19.21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.32"

  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::233736837022:role/gha-eks-admin"
      username = "gha-eks-admin"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::233736837022:user/ecs-workshop-user"
      username = "ecs-workshop-user"
      groups   = ["system:masters"]
    }
  ]

}

module "eks_node_group_default" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.36.0"

  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version
  subnet_ids      = module.vpc.private_subnets
  cluster_service_cidr = "172.20.0.0/16"

  name            = "default"
  instance_types  = [var.node_instance_type]
  desired_size    = var.desired_capacity
  min_size        = 1
  max_size        = 5

  ami_type        = "AL2_x86_64"
  capacity_type   = "ON_DEMAND"
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