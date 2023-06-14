module "eks_module" {
  source = "../dev/vpc"
}

output "eks_module_outputs" {
  value = {
    vpc_id                              = module.eks_module.vpc_id
    configure_kubectl                   = module.eks_module.configure_kubectl
    platform_teams_configure_kubectl    = module.eks_module.platform_teams_configure_kubectl
    application_teams_configure_kubectl = module.eks_module.application_teams_configure_kubectl
  }
}


