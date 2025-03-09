################################################################################
# IAM Module
################################################################################


resource "aws_iam_policy" "aws_loadbalancer_controller" {
  name        = "${local.name}-aws-loadbalancer-controller"
  path        = "/"
  description = "EKS AWS Load Balancer Controller Policy for cluster ${local.name}"


  policy = file("iam-policy.json")

  tags = local.tags
}

module "iam_assumable_role_aws_lb" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 4.12"

  create_role                   = true

  role_name                     = "${local.name}-aws-loadbalancer-controller"
  provider_url                  =  tostring(regex("oidc-provider/(.*)", module.eks.oidc_provider_arn)[0])

  role_policy_arns              = [aws_iam_policy.aws_loadbalancer_controller.arn]
  
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.k8s_aws_lb_service_account_namespace}:${local.k8s_aws_lb_service_account_name}"
  ]

  tags = local.tags
}


module "iam_assumable_role_cloudwatch" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = true

  role_name =  "${local.name}-cloudwatch-metrics"

  provider_url = tostring(regex("oidc-provider/(.*)", module.eks.oidc_provider_arn)[0])

  role_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  
  number_of_role_policy_arns = 1

  tags = local.tags
}