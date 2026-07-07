output "alb_dns_name" {
  description = "Public DNS name of the ALB — hit this to reach the app once deployed"
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint address (private, only reachable from ECS)"
  value       = module.rds.endpoint
}

output "vpc_id" {
  description = "VPC ID for this environment"
  value       = module.network.vpc_id
}