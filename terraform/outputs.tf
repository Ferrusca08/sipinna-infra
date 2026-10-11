output "api_endpoint" {
  description = "URL base del API HTTP. Va en la app Android y en el panel admin."
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito."
  value       = aws_cognito_user_pool.sipinna.id
}

output "cognito_user_pool_arn" {
  description = "ARN del User Pool."
  value       = aws_cognito_user_pool.sipinna.arn
}

output "cognito_client_id_admin" {
  description = "App Client del panel de administracion (token de 1 hora)."
  value       = aws_cognito_user_pool_client.admin.id
}

output "cognito_client_id_mobile" {
  description = "App Client de la app movil (token de 24 horas)."
  value       = aws_cognito_user_pool_client.mobile.id
}

output "cognito_domain" {
  description = "Dominio hospedado de Cognito."
  value       = "${aws_cognito_user_pool_domain.sipinna.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "bucket_evidencia" {
  description = "Bucket S3 de evidencia fotografica."
  value       = aws_s3_bucket.evidencia.id
}

output "bucket_admin" {
  description = "Bucket S3 del SPA de administracion."
  value       = aws_s3_bucket.admin.id
}

output "cloudfront_domain" {
  description = "Dominio publico del panel de administracion."
  value       = "https://${aws_cloudfront_distribution.admin.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID de la distribucion, necesario para invalidar cache tras cada despliegue."
  value       = aws_cloudfront_distribution.admin.id
}

output "tabla_reportes" {
  value       = aws_dynamodb_table.reportes.name
  description = "Tabla DynamoDB de reportes."
}

output "tabla_seguimiento" {
  value       = aws_dynamodb_table.seguimiento.name
  description = "Tabla DynamoDB de seguimiento."
}

output "tabla_auditlog" {
  value       = aws_dynamodb_table.auditlog.name
  description = "Tabla DynamoDB de auditoria."
}

output "sns_topic_nuevo_reporte" {
  value       = aws_sns_topic.nuevo_reporte.arn
  description = "Topic SNS de reportes nuevos."
}

output "sns_topic_reporte_urgente" {
  value       = aws_sns_topic.reporte_urgente.arn
  description = "Topic SNS de reportes urgentes."
}

output "kms_key_arn" {
  value       = aws_kms_key.sipinna.arn
  description = "Llave KMS que cifra la evidencia."
}

# Bloque listo para copiar al .env del panel admin.
output "env_admin_panel" {
  description = "Variables de entorno del panel de administracion."
  value       = <<-EOT
    VITE_API_URL=${aws_apigatewayv2_stage.prod.invoke_url}
    VITE_COGNITO_USER_POOL_ID=${aws_cognito_user_pool.sipinna.id}
    VITE_COGNITO_CLIENT_ID=${aws_cognito_user_pool_client.admin.id}
    VITE_AWS_REGION=${var.aws_region}
  EOT
}

output "cognito_ciudadania_user_pool_id" {
  description = "User pool de cuentas ciudadanas (distinto al del personal)."
  value       = aws_cognito_user_pool.ciudadania.id
}

output "cognito_ciudadania_client_id" {
  description = "Client ID que configura la app Android en local.properties."
  value       = aws_cognito_user_pool_client.ciudadania.id
}
