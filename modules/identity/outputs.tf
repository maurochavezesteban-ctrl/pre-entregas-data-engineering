output "data_processing_role_arn" {
  description = "ARN del rol de procesamiento de datos"
  value       = aws_iam_role.data_processing.arn
}

output "control_plane_readonly_role_arn" {
  description = "ARN del rol de lectura del plano de control"
  value       = aws_iam_role.control_plane_readonly.arn
}
