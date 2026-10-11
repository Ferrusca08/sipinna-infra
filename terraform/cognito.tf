resource "aws_cognito_user_pool" "sipinna" {
  name = "${local.name_prefix}-users"

  # El correo institucional es el identificador de acceso.
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 3
  }

  # MFA opcional por TOTP.
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true

    invite_message_template {
      email_subject = "Acceso al Panel SIPINNA Atizapan"
      email_message = "Hola, se creo tu cuenta para el Sistema de Reporte de Trabajo Infantil de SIPINNA Atizapan.<br/>Usuario: {username}<br/>Contrasena temporal: {####}<br/>Debes cambiarla y registrar tu app de autenticacion (TOTP) en el primer acceso."
      sms_message   = "Usuario SIPINNA: {username} Contrasena temporal: {####}"
    }
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
    name                     = "role"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 32
    }
  }

  schema {
    name                     = "full_name"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 128
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"
  }

  tags = {
    Name = "Usuarios SIPINNA"
  }
}

resource "aws_cognito_user_pool_domain" "sipinna" {
  domain       = "${local.name_prefix}-${local.account_id}"
  user_pool_id = aws_cognito_user_pool.sipinna.id
}

# ---------------------------------------------------------------------------
# Grupos = roles RBAC. La precedencia menor gana al resolver el rol efectivo.
# ---------------------------------------------------------------------------
resource "aws_cognito_user_group" "directivo" {
  name         = "directivo"
  user_pool_id = aws_cognito_user_pool.sipinna.id
  description  = "Acceso total: exportacion, gestion de usuarios y auditoria"
  precedence   = 1
}

resource "aws_cognito_user_group" "supervisor" {
  name         = "supervisor"
  user_pool_id = aws_cognito_user_pool.sipinna.id
  description  = "Asignacion de casos y metricas"
  precedence   = 2
}

resource "aws_cognito_user_group" "operador" {
  name         = "operador"
  user_pool_id = aws_cognito_user_pool.sipinna.id
  description  = "Atencion de reportes: estatus y notas"
  precedence   = 3
}

# ---------------------------------------------------------------------------
# App clients
# ---------------------------------------------------------------------------
resource "aws_cognito_user_pool_client" "admin" {
  name         = "${local.name_prefix}-admin-client"
  user_pool_id = aws_cognito_user_pool.sipinna.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 8

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "hours"
  }

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  read_attributes  = ["email", "email_verified", "custom:role", "custom:full_name"]
  write_attributes = ["email", "custom:full_name"]
}

resource "aws_cognito_user_pool_client" "mobile" {
  name         = "${local.name_prefix}-mobile-client"
  user_pool_id = aws_cognito_user_pool.sipinna.id

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

  read_attributes  = ["email", "email_verified", "custom:role", "custom:full_name"]
  write_attributes = ["email", "custom:full_name"]
}
