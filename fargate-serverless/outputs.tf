output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "oidc_issuer_url" {
  value = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  value = tostring(regex("oidc-provider/(.*)", module.eks.oidc_provider_arn)[0])
}
