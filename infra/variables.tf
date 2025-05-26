variable "cluster_name" {
  type    = string
  default = "demo-eks-v00"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "desired_capacity" {
  type    = number
  default = 2
}
