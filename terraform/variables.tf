variable "aws_region" {
  description = "Region de AWS donde se despliega toda la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo corto del proyecto, usado para nombrar recursos."
  type        = string
  default     = "sipinna"
}

variable "environment" {
  description = "Entorno de despliegue."
  type        = string
  default     = "prod"
}

# Los nombres de bucket S3 son globalmente unicos. Si alguno ya esta tomado por
# otra cuenta, sobreescribe estas variables en terraform.tfvars.
variable "evidencia_bucket_name" {
  description = "Nombre del bucket S3 para evidencia fotografica."
  type        = string
  default     = "sipinna-evidencia-prod"
}

variable "admin_bucket_name" {
  description = "Nombre del bucket S3 que hospeda el SPA de administracion."
  type        = string
  default     = "sipinna-admin-prod"
}

variable "log_retention_days" {
  description = "Retencion de los log groups de CloudWatch, en dias."
  type        = number
  default     = 90
}

variable "lambda_memory_mb" {
  description = "Memoria asignada a cada funcion Lambda."
  type        = number
  default     = 256
}

variable "lambda_timeout_seconds" {
  description = "Timeout de cada funcion Lambda."
  type        = number
  default     = 15
}

variable "alerta_email" {
  description = "Correo que recibe las notificaciones SNS de reportes urgentes. Vacio = no se crea la suscripcion."
  type        = string
  default     = ""
}

variable "presigned_url_expiration_seconds" {
  description = "Vigencia de las presigned URLs de evidencia."
  type        = number
  default     = 900
}

variable "cors_allowed_origins" {
  description = "Origenes permitidos por CORS en el API."
  type        = list(string)
  default     = ["*"]
}
