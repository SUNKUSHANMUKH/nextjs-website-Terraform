output "ecr_repository_url" {
  description = "ECR repo URL — use this as ECR_REGISTRY in GitHub Secrets"
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name — test your app here before DNS propagates"
  value       = module.alb.alb_dns_name
}

output "app_url" {
  description = "Your application URL"
  value       = "https://app.${var.domain_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}
