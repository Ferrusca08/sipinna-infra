resource "aws_kms_key" "sipinna" {
  description             = "Llave KMS para evidencia fotografica de reportes SIPINNA"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccount"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowS3Service"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "sipinna" {
  name          = "alias/${local.name_prefix}-evidencia"
  target_key_id = aws_kms_key.sipinna.key_id
}
