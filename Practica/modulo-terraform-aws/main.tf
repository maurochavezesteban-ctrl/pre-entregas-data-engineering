terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" 
      version = "~> 5.0"
    }
  }
}

# 2. Configuración de la región
provider "aws" {
  region = "us-east-1"
}

# 3. Definir nuestro Bucket S3 (Capa Raw / Datos Crudos)
resource "aws_s3_bucket" "data_lake_raw" {
  bucket        = "coderhouse-datalake-raw-prueba-semana1"
  force_destroy = true

  tags = {
    Environment = "Dev"
    Project     = "DataOps-Course"
  }
}

#validar sintaxis y formato: terraform fmt -check/ Generar el Plan:terraform plan -no-color > PLAN_OUTPUT.md / terraform destroy -auto-approve
