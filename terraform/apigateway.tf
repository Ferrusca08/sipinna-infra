resource "aws_apigatewayv2_api" "sipinna" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"
  description   = "API del Sistema de Reporte de Trabajo Infantil - SIPINNA Atizapan"

  cors_configuration {
    allow_origins  = var.cors_allowed_origins
    allow_methods  = ["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"]
    allow_headers  = ["content-type", "authorization", "x-amz-date", "x-api-key", "x-amz-security-token"]
    expose_headers = ["x-total-count"]
    max_age        = 3600
  }
}

# Autorizador JWT contra el user pool: protege todo /admin/*.
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.sipinna.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name_prefix}-cognito-jwt"

  jwt_configuration {
    audience = [
      aws_cognito_user_pool_client.admin.id,
      aws_cognito_user_pool_client.mobile.id,
    ]
    issuer = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.sipinna.id}"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each = local.lambdas

  api_id                 = aws_apigatewayv2_api.sipinna.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.handler[each.key].invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = var.lambda_timeout_seconds * 1000
}

locals {
  # route_key => { fn = nombre de la lambda, auth = ninguno | panel | ciudadania }
  #
  # "ninguno" no siempre significa anonimo: POST /reportes sigue abierto para
  # que se pueda denunciar sin cuenta, pero si la peticion trae un token de
  # ciudadania la lambda lo valida por su cuenta y amarra el reporte a esa
  # persona. API Gateway no sabe hacer un JWT opcional por ruta.
  rutas = {
    # --- Publicas (ciudadano) ---
    "POST /reportes"                = { fn = "crearReporte", auth = "ninguno" }
    "GET /reportes/{id}/estatus"    = { fn = "consultarEstatus", auth = "ninguno" }
    "POST /reportes/{id}/evidencia" = { fn = "evidencia", auth = "ninguno" }

    # --- Ciudadania autenticada ---
    "GET /mis-reportes" = { fn = "misReportes", auth = "ciudadania" }

    # --- Protegidas (personal SIPINNA) ---
    "GET /admin/reportes"                   = { fn = "listarReportes", auth = "panel" }
    "GET /admin/reportes/{id}"              = { fn = "obtenerReporte", auth = "panel" }
    "PATCH /admin/reportes/{id}"            = { fn = "actualizarReporte", auth = "panel" }
    "POST /admin/reportes/{id}/seguimiento" = { fn = "agregarSeguimiento", auth = "panel" }
    "GET /admin/estadisticas"               = { fn = "estadisticas", auth = "panel" }
    "GET /admin/estadisticas/heatmap"       = { fn = "heatmap", auth = "panel" }
    "GET /admin/usuarios"                   = { fn = "usuarios", auth = "panel" }
    "POST /admin/usuarios"                  = { fn = "usuarios", auth = "panel" }
    "POST /admin/exportar"                  = { fn = "exportar", auth = "panel" }
    "GET /admin/auditlog"                   = { fn = "auditlog", auth = "panel" }
  }
}

resource "aws_apigatewayv2_route" "rutas" {
  for_each = local.rutas

  api_id    = aws_apigatewayv2_api.sipinna.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.value.fn].id}"

  authorization_type = each.value.auth == "ninguno" ? "NONE" : "JWT"

  authorizer_id = lookup(
    {
      panel      = aws_apigatewayv2_authorizer.cognito.id
      ciudadania = aws_apigatewayv2_authorizer.ciudadania.id
    },
    each.value.auth,
    null,
  )
}

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.sipinna.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      userSub          = "$context.authorizer.claims.sub"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 200
    throttling_rate_limit    = 100
  }
}
