locals {
  name     = basename(path.cwd)
  region   = "us-east-2"
  app_name = "app-2025"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  k8s_aws_lb_service_account_namespace = "kube-system"
  k8s_aws_lb_service_account_name      = "aws-load-balancer-controller-sa"
  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"
  cluster_name                   = local.name
  cluster_version                = "1.32"
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access  = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enables OIDC Provider for IRSA
  enable_irsa = true

  # Fargate profiles use the cluster primary security group so these are not utilized

  create_cluster_security_group = false

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  create_node_security_group    = false

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      self        = true
    }
  }

  fargate_profiles = {
    app_wildcard = {
      selectors = [
        { namespace = "app-2025" }
      ]
    }
    kube_system = {
      name = "kube-system"
      selectors = [
        { namespace = "kube-system" }
      ]
    }
  }
  fargate_profile_defaults = {
    iam_role_additional_policies = {
      custom_policy  = aws_iam_policy.custom_fargate_policy.arn 
      fluentbit_policy  = module.eks_blueprints_addons.fargate_fluentbit.iam_policy[0].arn
    }
  }
  tags = local.tags
}

# Custom Fargate Policy
resource "aws_iam_policy" "custom_fargate_policy" {
  name        = "CustomFargatePolicy"
  description = "Custom policy for Fargate profile to allow logging, ECR access, and S3 reads"
  
  policy = file("custom_fargate_policy.json")
}

