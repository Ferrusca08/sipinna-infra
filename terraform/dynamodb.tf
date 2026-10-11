# ---------------------------------------------------------------------------
# Tabla principal de reportes ciudadanos
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "reportes" {
  name         = "${var.project_name}-reportes-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "reporteId"
  range_key    = "fechaCreacion"

  attribute {
    name = "reporteId"
    type = "S"
  }
  attribute {
    name = "fechaCreacion"
    type = "S"
  }
  attribute {
    name = "estatus"
    type = "S"
  }
  attribute {
    name = "zonaGeografica"
    type = "S"
  }
  attribute {
    name = "operadorAsignado"
    type = "S"
  }
  attribute {
    name = "prioridad"
    type = "S"
  }

  attribute {
    name = "reportanteId"
    type = "S"
  }

  global_secondary_index {
    name            = "estatus-fecha-index"
    hash_key        = "estatus"
    range_key       = "fechaCreacion"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "zona-fecha-index"
    hash_key        = "zonaGeografica"
    range_key       = "fechaCreacion"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "operador-fecha-index"
    hash_key        = "operadorAsignado"
    range_key       = "fechaCreacion"
    projection_type = "ALL"
  }

  # Sin este indice, "mis reportes" obligaria a escanear la tabla entera y
  # filtrar en memoria: caro y cada vez mas lento. Los reportes anonimos no
  # llevan reportanteId, asi que simplemente no entran al indice.
  global_secondary_index {
    name            = "reportante-fecha-index"
    hash_key        = "reportanteId"
    range_key       = "fechaCreacion"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "prioridad-fecha-index"
    hash_key        = "prioridad"
    range_key       = "fechaCreacion"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "Reportes de trabajo infantil"
  }
}

# ---------------------------------------------------------------------------
# Bitacora de seguimiento por caso
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "seguimiento" {
  name         = "${var.project_name}-seguimiento-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "reporteId"
  range_key    = "seguimientoId"

  attribute {
    name = "reporteId"
    type = "S"
  }
  attribute {
    name = "seguimientoId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "Seguimiento de casos"
  }
}

# ---------------------------------------------------------------------------
# Log de auditoria (TTL a 1 anio)
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "auditlog" {
  name         = "${var.project_name}-auditlog-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "logId"
  range_key    = "timestamp"

  attribute {
    name = "logId"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "S"
  }
  attribute {
    name = "userId"
    type = "S"
  }

  global_secondary_index {
    name            = "userId-timestamp-index"
    hash_key        = "userId"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expiraEn"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "Auditoria de acciones administrativas"
  }
}
