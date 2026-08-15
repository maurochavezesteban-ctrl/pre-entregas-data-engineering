variable "environment" {
  description = "Nombre del ambiente (ej: dev, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Región de AWS."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "data_lake_bucket_arn" {
  description = "ARN del bucket S3 del Data Lake existente."
  type        = string
  default     = "arn:aws:s3:::coderhouse-datalake-raw-prueba-semana1"
}

variable "data_lake_prefix" {
  description = "Prefijo dentro del bucket del Data Lake."
  type        = string
  default     = "raw/"
}

variable "assume_role_services" {
  description = "Lista de servicios de AWS que pueden asumir el rol."
  type        = list(string)
  default     = ["glue.amazonaws.com"]
}

variable "control_plane_trusted_arn" {
  description = "ARN del usuario IAM confiable que puede asumir el rol de auditoría de solo lectura."
  type        = string
  default     = "arn:aws:iam::426143721475:user/Mauro"
}
