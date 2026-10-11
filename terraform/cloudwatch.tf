# crearReporte emite la linea "REPORTE_URGENTE" cuando clasifica un caso como
# urgente; el metric filter la convierte en metrica para poder alarmar.
resource "aws_cloudwatch_log_metric_filter" "reportes_urgentes" {
  name           = "${local.name_prefix}-reportes-urgentes"
  log_group_name = aws_cloudwatch_log_group.lambda["crearReporte"].name
  pattern        = "REPORTE_URGENTE"

  metric_transformation {
    name          = "ReportesUrgentes"
    namespace     = "SIPINNA/Reportes"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "pico_reportes_urgentes" {
  alarm_name          = "${local.name_prefix}-pico-reportes-urgentes"
  alarm_description   = "Mas de 5 reportes urgentes en una ventana de 5 minutos"
  namespace           = "SIPINNA/Reportes"
  metric_name         = "ReportesUrgentes"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.reporte_urgente.arn]
  ok_actions    = []

  depends_on = [aws_cloudwatch_log_metric_filter.reportes_urgentes]
}

resource "aws_cloudwatch_metric_alarm" "errores_lambda" {
  for_each = local.lambdas

  alarm_name          = "${local.name_prefix}-${each.key}-errores"
  alarm_description   = "Errores en la funcion ${each.key}"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.handler[each.key].function_name
  }

  alarm_actions = [aws_sns_topic.nuevo_reporte.arn]
}

resource "aws_cloudwatch_metric_alarm" "errores_api_5xx" {
  alarm_name          = "${local.name_prefix}-api-5xx"
  alarm_description   = "Errores 5xx en el API Gateway"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.sipinna.id
  }

  alarm_actions = [aws_sns_topic.nuevo_reporte.arn]
}
