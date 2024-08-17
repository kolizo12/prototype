resource "kubectl_manifest" "karpenter_default_ec2_node_class" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  role: "${local.node_iam_role_name}"
  amiFamily: AL2
  securityGroupSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  subnetSelectorTerms:
  - tags:
      karpenter.sh/discovery: ${local.name}
  tags:
    IntentLabel: apps
    KarpenterNodePoolName: default
    NodeType: default
    intent: apps
    karpenter.sh/discovery: ${local.name}
    project: karpenter-blueprints
YAML
  depends_on = [
    module.eks.cluster,
    helm_release.karpenter,
  ]
}

resource "kubectl_manifest" "karpenter_default_node_pool" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default 
spec:  
  template:
    metadata:
      labels:
        intent: apps
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]
        - key: karpenter.k8s.aws/instance-cpu
          operator: In
          values: ["2", "4", "8", "16"]  # Smaller instances
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]  # Include spot instances
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["t", "m", "c", "r"]  # Add t instances (cheaper)
      nodeClassRef:
        name: default
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
      kubelet:
        containerRuntime: containerd
        systemReserved:
          cpu: 100m
          memory: 100Mi
  disruption:
    consolidationPolicy: WhenUnderutilized
YAML
  depends_on = [
    module.eks.cluster,
    helm_release.karpenter,
    kubectl_manifest.karpenter_default_ec2_node_class,
  ]
}
