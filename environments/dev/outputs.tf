output "vpc_id" {
  description = "ID de la VPC creada por el módulo network."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas creadas por el módulo network."
  value       = module.network.private_subnet_ids
}

output "data_processing_role_arn" {
  description = "ARN del rol IAM para procesamiento de datos (Lambda/Flink futuro)."
  value       = module.identity.data_processing_role_arn
}

output "control_plane_role_arn" {
  description = "ARN del rol IAM de solo lectura para auditoría del plano de control."
  value       = module.identity.control_plane_readonly_role_arn
}