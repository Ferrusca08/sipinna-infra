resource "aws_sns_topic" "nuevo_reporte" {
  name              = "${var.project_name}-nuevo-reporte"
  display_name      = "SIPINNA nuevo reporte"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "Notificacion de reporte nuevo"
  }
}

resource "aws_sns_topic" "reporte_urgente" {
  name              = "${var.project_name}-reporte-urgente"
  display_name      = "SIPINNA URGENTE"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "Notificacion de reporte urgente"
  }
}

# Suscripcion opcional por correo: solo se crea si se define alerta_email.
resource "aws_sns_topic_subscription" "nuevo_reporte_email" {
  count     = var.alerta_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.nuevo_reporte.arn
  protocol  = "email"
  endpoint  = var.alerta_email
}

resource "aws_sns_topic_subscription" "reporte_urgente_email" {
  count     = var.alerta_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.reporte_urgente.arn
  protocol  = "email"
  endpoint  = var.alerta_email
}
