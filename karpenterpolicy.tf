data "aws_iam_policy_document" "node_assume_role_policy" {
    statement {
      actions = ["sts:AssumeRole"]
  
      principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }
    }
  }
  
  resource "aws_iam_role_policy" "karpenter_controller_policy" {
    name   = "KarpenterControllerPolicy-${local.name}"
    role   = local.node_iam_role_name
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "ssm:GetParameter",
            "ec2:DescribeImages",
            "ec2:RunInstances",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeLaunchTemplates",
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceTypes",
            "ec2:DescribeInstanceTypeOfferings",
            "ec2:DescribeAvailabilityZones",
            "ec2:DeleteLaunchTemplate",
            "ec2:CreateTags",
            "ec2:CreateLaunchTemplate",
            "ec2:CreateFleet",
            "ec2:DescribeSpotPriceHistory",
            "pricing:GetProducts"
          ],
          Resource = "*",
          Sid      = "Karpenter"
        },
        {
          Effect = "Allow",
          Action = "ec2:TerminateInstances",
          Condition = {
            StringLike = {
              "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
            }
          },
          Resource = "*",
          Sid      = "ConditionalEC2Termination"
        },
        {
          Effect = "Allow",
          Action = "iam:PassRole",
          Resource = module.eks.eks_managed_node_groups["initial"].iam_role_arn,
          Sid      = "PassNodeIAMRole"
        },
        {
          Effect = "Allow",
          Action = "eks:DescribeCluster",
          Resource = "arn:aws:eks:${local.region}:${local.aws_account_id}:cluster/${local.name}",
          Sid      = "EKSClusterEndpointLookup"
        },
        {
          Sid      = "AllowScopedInstanceProfileCreationActions",
          Effect   = "Allow",
          Resource = "*",
          Action   = [
            "iam:CreateInstanceProfile"
          ],
          Condition = {
            StringEquals = {
              "aws:RequestTag/kubernetes.io/clfuster/${local.name}" = "owned",
              "aws:RequestTag/topology.kubernetes.io/region"       = local.region
            },
            StringLike = {
              "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            }
          }
        },
        {
          Sid      = "AllowScopedInstanceProfileTagActions",
          Effect   = "Allow",
          Resource = "*",
          Action   = [
            "iam:TagInstanceProfile"
          ],
          Condition = {
            StringEquals = {
              "aws:ResourceTag/kubernetes.io/cluster/${local.name}" = "owned",
              "aws:ResourceTag/topology.kubernetes.io/region"       = local.region,
              "aws:RequestTag/kubernetes.io/cluster/${local.name}" = "owned",
              "aws:RequestTag/topology.kubernetes.io/region"       = local.region
            },
            StringLike = {
              "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*",
              "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
            }
          }
        },
        {
          Sid      = "AllowScopedInstanceProfileActions",
          Effect   = "Allow",
          Resource = "*",
          Action   = [
            "iam:AddRoleToInstanceProfile",
            "iam:RemoveRoleFromInstanceProfile",
            "iam:DeleteInstanceProfile"
          ],
          Condition = {
            StringEquals = {
              "aws:ResourceTag/kubernetes.io/cluster/${local.name}" = "owned",
              "aws:ResourceTag/topology.kubernetes.io/region"       = local.region
            }
          }
        },
        {
          Sid      = "AllowInstanceProfileReadActions",
          Effect   = "Allow",
          Resource = "*",
          Action   = "iam:GetInstanceProfile"
        }
      ]
    })
  }
  
  resource "aws_iam_role_policy" "karpenter_irsa_policy" {
    name = "KarpenterIRSAPolicy-${local.name}"
    role = local.node_iam_role_name
  
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = "sts:AssumeRoleWithWebIdentity",
          Resource = "*",  # Specify the resource here or remove this line if not applicable
          Condition = {
            StringEquals = {
              "${local.oidc_endpoint}:aud" = "sts.amazonaws.com",
              "${local.oidc_endpoint}:sub" = "system:serviceaccount:kube-system:karpenter"
            }
          }
        }
      ]
    })
  }
  