# Directorio de cuentas ciudadanas.
#
# Va en un user pool propio y no en el del personal: aquel es por invitacion
# (allow_admin_create_user_only) y sus integrantes llevan grupos RBAC que dan
# acceso al panel. Si se abriera el alta ahi, cualquiera en internet quedaria
# registrado en el mismo directorio que el personal de SIPINNA, apareceria en
# GET /admin/usuarios y un error al asignar grupos se volveria un problema de
# seguridad. Separados, un alta ciudadana no puede escalar a nada del panel.
#
# El reporte anonimo sigue siendo el camino principal: la cuenta solo sirve para
# que quien reporta pueda seguir sus propios casos sin cargar con el folio.

resource "aws_cognito_user_pool" "ciudadania" {
  name = "${local.name_prefix}-ciudadania"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  # Mas ligera que la del personal: aqui no hay acceso a datos de terceros, y
  # una politica dura solo empuja a la gente a no crear la cuenta.
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = false
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # Sin MFA: friccion innecesaria para una cuenta que no abre datos sensibles.
  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Alta abierta: es justo lo que distingue a este pool del otro.
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Tu codigo de SIPINNA Atizapan"
    email_message        = "Tu codigo de verificacion es {####}. Escribelo en la app para activar tu cuenta."
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    name                     = "nombre"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 0
      max_length = 120
    }
  }

  # Deja rastro de intentos sospechosos sin bloquear a nadie por error.
  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  tags = {
    Contenido = "Cuentas de ciudadania, sin acceso al panel"
  }
}

resource "aws_cognito_user_pool_client" "ciudadania" {
  user_pool_id = aws_cognito_user_pool.ciudadania.id
  name         = "${local.name_prefix}-ciudadania-client"

  # App publica instalada en telefonos: no puede guardar un secreto.
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = 24
  id_token_validity      = 24
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  read_attributes  = ["email", "email_verified", "custom:nombre"]
  write_attributes = ["email", "custom:nombre"]
}

# API Gateway admite un solo emisor por autorizador, asi que la ciudadania
# necesita el suyo. Separarlos tambien evita que un token del panel sirva para
# las rutas ciudadanas y al reves.
resource "aws_apigatewayv2_authorizer" "ciudadania" {
  api_id           = aws_apigatewayv2_api.sipinna.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name_prefix}-ciudadania-jwt"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.ciudadania.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.ciudadania.id}"
  }
}
