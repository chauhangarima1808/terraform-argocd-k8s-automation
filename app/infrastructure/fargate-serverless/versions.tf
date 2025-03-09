terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.34"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }

  # ##  Used for end-to-end testing on project; update to suit your needs
  backend "s3" {
    bucket         = "terraform-eks-app-deployment"
    key            = "fargate-k8s/terraform.tfstate"
    region         = "us-east-1"
    profile        = "webeksauto"
    dynamodb_table = "terraform-eks-app-deployment-lock"
  }
}