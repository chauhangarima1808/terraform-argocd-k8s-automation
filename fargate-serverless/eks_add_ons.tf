################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  # We want to wait for the Fargate profiles to be deployed first
  create_delay_dependencies = [for prof in module.eks.fargate_profiles : prof.fargate_profile_arn]
  # EKS Add-ons
  eks_addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
        resources = {
          limits = {
            cpu = "0.25"
            memory = "256M"
          }
          requests = {
            cpu = "0.25"
            memory = "256M"
          }
        }
      })
    }
    vpc-cni    = {}
    kube-proxy = {}
  }

  # Enable Fargate logging this may generate a large ammount of logs, disable it if not explicitly required

  enable_fargate_fluentbit = true
  fargate_fluentbit = {
    flb_log_cw = true
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      {
        name  = "podDisruptionBudget.maxUnavailable"
        value = 1
      },
      {
        name  = "serviceAccount.create"
        value = true
      },
      {
        name  = "serviceAccount.name"
        value = "aws-load-balancer-controller-sa"
      },
      {
        name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = module.iam_assumable_role_aws_lb.iam_role_arn
      }
    ]
  }
  depends_on = [
    aws_iam_policy.aws_loadbalancer_controller
  ]
  tags = local.tags
}



