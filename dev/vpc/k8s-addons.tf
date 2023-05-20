module "kubernetes_addons" {
    source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.27.0"

    eks_cluster_id = module.eks_blueprints.eks_cluster_id

    #EKS Add-ons
    enable_amazon_eks_aws_ebs_csi_driver = true
    enable_aws_load_balancer_controller = true
    enable_metrics_server = true
    enable_cert_manager = true

    enable_velero           = true
    velero_backup_s3_bucket = module.velero_backup_s3_bucket.s3_bucket_id




}

