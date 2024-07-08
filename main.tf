provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}
provider "aws" {
  region = local.region
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

locals {
  name                   = "demo"
  region                 = "us-west-1"
  node_iam_role_name     = module.eks.eks_managed_node_groups["initial"].iam_role_name
  vpc_cidr               = "10.0.0.0/16"
  vpc_id                 = module.vpc.vpc_id
  irsa_ebs_csi_role_name = "AmazonEKSTFEBSCSIRole-${local.name}"
  aws_account_id         = data.aws_caller_identity.current.account_id
  oidc_endpoint       = module.eks.cluster_oidc_issuer_url
  aws_partition       = "aws"
  karpenter_namespace = "kube-system"



  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Blueprint  = local.name
    GithubRepo = "https://git.tabbank.com/Operations/aws-terraform"
  }
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
  }

  tags = local.tags
}

module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "19.15.4"
  cluster_name                    = local.name
  cluster_version                 = "1.28"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = false
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets

  eks_managed_node_groups = {
    initial = {
      ami_type = "AL2023_x86_64_STANDARD"

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
      instance_types = ["m5.large"]
      taints = {
        # The pods that do not tolerate this taint should run on nodes
        # created by Karpenter
        karpenter = {
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }

      min_size     = 1
      max_size     = 5
      desired_size = 3

     iam_role_additional_policies = { policy = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",}


    }
  }
  manage_aws_auth_configmap = true
  aws_auth_roles = flatten([
    module.eks_blueprints_admin_team.aws_auth_configmap_role,
    # [for team in module.eks_blueprints_dev_teams : team.aws_auth_configmap_role],
  ])

  tags = merge(local.tags, { "karpenter.sh/discovery" = local.name })
}

################################################################################
# EKS Blueprints Teams
################################################################################

module "eks_blueprints_admin_team" {
  source  = "aws-ia/eks-blueprints-teams/aws"
  version = "~> 1.0"

  name = "admin-team"

  enable_admin = true
  users        = [data.aws_caller_identity.current.arn]
  cluster_arn  = module.eks.cluster_arn

  tags = local.tags
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name} --region ${local.region}"
}

module "eks_blueprints_addons" {
  source            = "aws-ia/eks-blueprints-addons/aws"
  version           = "v1.14.0"
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  #currently all kube-proxy addons should be done via aws dashbaord
  eks_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    eks-pod-identity-agent = {}
  }

  enable_aws_load_balancer_controller = false
}

