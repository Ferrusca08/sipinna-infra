# SIPINNA Atizapán — Infraestructura

Terraform de la infraestructura AWS del Sistema de Reporte de Trabajo Infantil
de SIPINNA Atizapán de Zaragoza.

Este repositorio contiene únicamente la definición de la infraestructura. El
estado de Terraform queda excluido del control de versiones, porque guarda
valores sensibles en claro.

El código de aplicación vive en repositorios aparte:
[movil](https://github.com/Ferrusca08/sipinna-movil) ·
[admin](https://github.com/Ferrusca08/sipinna-admin) ·
[backend](https://github.com/Ferrusca08/sipinna-backend).

## Qué se despliega

Región `us-east-1`, prefijo `sipinna-prod`.

| Servicio | Para qué |
|---|---|
| Lambda | 13 funciones, artefacto compartido, Node 20, arm64 |
| API Gateway HTTP | Entrada del API, dos autorizadores JWT |
| DynamoDB | 3 tablas bajo demanda, PITR activo |
| Cognito | Dos pools separados: personal y ciudadanía |
| S3 | Evidencia (KMS, versionado, ciclo de vida) y panel |
| KMS | Llave propia con rotación para la evidencia |
| CloudFront | Distribución del panel con OAC y cabeceras de seguridad |
| SNS | Avisos de reporte nuevo y de urgente |
| CloudWatch | Logs a 90 días y alarmas de pico, errores y 5xx |

## Dos pools de Cognito, a propósito

El del personal es por invitación y sus integrantes llevan grupos RBAC que abren
el panel. El de la ciudadanía tiene alta libre. Si se abriera el alta en el
primero, cualquiera quedaría registrado en el mismo directorio que el personal y
un error al asignar grupos se volvería un problema de seguridad.

## Pendientes conocidos

- **El `tfstate` es local.** Debe migrarse a un backend S3 con bloqueo. Hoy el
  estado vive en la máquina de quien aplicó por última vez.
- **`cors_allowed_origins` está en `["*"]`.** Debe restringirse al dominio real
  del panel.

## Uso

```bash
terraform init
terraform plan
terraform apply
```
