variable "vpc_cidr" {
  description = "Rango de IPs de la VPC"
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (ej: dev)"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}
