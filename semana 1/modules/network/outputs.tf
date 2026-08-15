output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas creadas"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}
