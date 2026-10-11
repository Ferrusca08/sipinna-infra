data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  # --- CloudWatch Logs -----------------------------------------------------
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-*:*"]
  }

  # --- DynamoDB: solo las tres tablas del sistema y sus indices ------------
  statement {
    sid    = "DynamoDbCrud"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
    ]
    resources = [
      aws_dynamodb_table.reportes.arn,
      "${aws_dynamodb_table.reportes.arn}/index/*",
      aws_dynamodb_table.seguimiento.arn,
      "${aws_dynamodb_table.seguimiento.arn}/index/*",
      aws_dynamodb_table.auditlog.arn,
      "${aws_dynamodb_table.auditlog.arn}/index/*",
    ]
  }

  # --- S3: objetos de evidencia y exportaciones ----------------------------
  statement {
    sid    = "S3Objetos"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = ["${aws_s3_bucket.evidencia.arn}/*"]
  }

  statement {
    sid       = "S3Listado"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.evidencia.arn]
  }

  # --- SNS -----------------------------------------------------------------
  statement {
    sid     = "SnsPublish"
    effect  = "Allow"
    actions = ["sns:Publish"]
    resources = [
      aws_sns_topic.nuevo_reporte.arn,
      aws_sns_topic.reporte_urgente.arn,
    ]
  }

  # --- KMS: cifrado de evidencia ------------------------------------------
  statement {
    sid    = "Kms"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.sipinna.arn]
  }

  # --- Cognito: la pantalla de usuarios lista y crea operadores ------------
  statement {
    sid    = "CognitoAdmin"
    effect = "Allow"
    actions = [
      "cognito-idp:ListUsers",
      "cognito-idp:ListUsersInGroup",
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminListGroupsForUser",
      "cognito-idp:AdminCreateUser",
      "cognito-idp:AdminAddUserToGroup",
      "cognito-idp:AdminDisableUser",
      "cognito-idp:AdminEnableUser",
    ]
    resources = [aws_cognito_user_pool.sipinna.arn]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.name_prefix}-lambda-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}
