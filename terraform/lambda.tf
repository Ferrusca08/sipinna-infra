locals {
  backend_dir = "${path.module}/../../backend"

  # Un solo artefacto compartido; cada funcion apunta a su propio handler.
  lambdas = {
    crearReporte       = "Alta de reporte ciudadano"
    evidencia          = "Presigned URLs y registro de evidencia"
    consultarEstatus   = "Consulta publica de estatus por token"
    listarReportes     = "Listado paginado con filtros"
    obtenerReporte     = "Detalle completo de un reporte"
    actualizarReporte  = "Cambio de estatus, prioridad y asignacion"
    agregarSeguimiento = "Registro de acciones de seguimiento"
    estadisticas       = "Metricas agregadas del tablero"
    heatmap            = "Datos geograficos ponderados"
    misReportes        = "Reportes propios de una cuenta ciudadana"
    exportar           = "Generacion de CSV y PDF"
    usuarios           = "Consulta de usuarios de Cognito"
    auditlog           = "Consulta del log de auditoria"
  }
}



resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.lambdas

  name              = "/aws/lambda/${local.name_prefix}-${each.key}"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "handler" {
  for_each = local.lambdas

  function_name = "${local.name_prefix}-${each.key}"
  description   = each.value
  role          = aws_iam_role.lambda.arn
  runtime       = "nodejs20.x"
  handler       = "src/handlers/${each.key}.handler"
  architectures = ["arm64"]

  filename         = "${path.module}/.build/backend.zip"
  source_code_hash = filebase64sha256("${path.module}/.build/backend.zip")

  memory_size = var.lambda_memory_mb
  timeout     = var.lambda_timeout_seconds

  environment {
    variables = {
      TABLA_REPORTES    = aws_dynamodb_table.reportes.name
      TABLA_SEGUIMIENTO = aws_dynamodb_table.seguimiento.name
      TABLA_AUDITLOG    = aws_dynamodb_table.auditlog.name
      BUCKET_EVIDENCIA  = aws_s3_bucket.evidencia.id
      KMS_KEY_ID        = aws_kms_key.sipinna.arn
      TOPIC_NUEVO       = aws_sns_topic.nuevo_reporte.arn
      TOPIC_URGENTE     = aws_sns_topic.reporte_urgente.arn
      USER_POOL_ID      = aws_cognito_user_pool.sipinna.id

      # Pool de ciudadania: lo usa crearReporte para reconocer una sesion en
      # una ruta que no pasa por el autorizador.
      USER_POOL_ID_CIUDADANIA      = aws_cognito_user_pool.ciudadania.id
      COGNITO_CLIENT_ID_CIUDADANIA = aws_cognito_user_pool_client.ciudadania.id
      PRESIGN_EXPIRA_SEG           = tostring(var.presigned_url_expiration_seconds)
      CORS_ORIGENES                = join(",", var.cors_allowed_origins)
      NODE_OPTIONS                 = "--enable-source-maps"
    }
  }

  logging_config {
    log_format = "JSON"
    log_group  = aws_cloudwatch_log_group.lambda[each.key].name
  }

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_cloudwatch_log_group.lambda,
  ]
}

resource "aws_lambda_permission" "apigw" {
  for_each = local.lambdas

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.sipinna.execution_arn}/*/*"
}
