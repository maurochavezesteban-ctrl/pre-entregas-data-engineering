variable "environment" {
  description = "Nombre del entorno (ej: dev)"
  type        = string
}

variable "data_lake_bucket_arn" {
  description = "ARN del bucket S3 del Data Lake existente"
  type        = string
}

variable "data_lake_prefix" {
  description = "Prefijo dentro del bucket del Data Lake"
  type        = string
}

variable "assume_role_services" {
  description = "Lista de servicios que pueden asumir el rol de procesamiento"
  type        = list(string)
}

variable "control_plane_trusted_arn" {
  description = "ARN del usuario IAM confiable para auditoría"
  type        = string
}
