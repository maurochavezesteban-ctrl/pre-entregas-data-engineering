# Pre-entrega 1 — Infraestructura Base con Entorno de Desarrollo e IAM Core

Proyecto de Terraform sobre AWS correspondiente a la Pre-entrega 1 del curso de Ingeniería de Datos (Coderhouse). Implementa el andamiaje base de una arquitectura de datos: red privada, backend remoto de Terraform e identidades IAM con mínimo privilegio, como preparación para futuras pre-entregas de ingesta y procesamiento.

## 1. Objetivo del proyecto

Levantar la infraestructura base sobre la que se construirán los próximos módulos del curso (ingesta real-time, procesamiento), priorizando:

- Gobernanza de infraestructura mediante Terraform modularizado.
- Estado remoto compartido y bloqueado (S3 + DynamoDB).
- Red privada sin exposición directa a Internet.
- Roles IAM de mínimo privilegio, sin permisos administrativos innecesarios.

No se incluyen en esta etapa servicios de streaming ni procesamiento (Kinesis, Lambda, Firehose): quedan fuera de alcance y corresponden a la Pre-entrega 2.

## 2. Arquitectura

```
Backend remoto (bootstrap manual, fuera del state)
   S3 (state, versionado, cifrado SSE) + DynamoDB (locking)
        │
        ▼
environments/dev  (orquesta los módulos vía variables)
        │
   ┌────┴─────┐
   ▼          ▼
network    identity
   │          │
   VPC        Data Processing Role
   2 subnets  → policy S3 (ListBucket/GetObject/PutObject)
   privadas     restringida al prefijo "raw/" del bucket
   (AZs         del Data Lake existente
   distintas)
   route      Control Plane Read-Only Role
   tables     → policy custom de solo lectura sobre
   S3 Gateway   los recursos de este mismo proyecto
   Endpoint     (VPC/IAM), sin acceso a otros servicios
```

**Cómo se relacionan las piezas:**

- Las subnets privadas no tienen ruta hacia un Internet Gateway, por lo que no tienen salida directa a Internet.
- El **S3 Gateway Endpoint** está asociado a las route tables de ambas subnets privadas, permitiendo que futuros recursos desplegados ahí (Lambda, Flink, etc.) accedan a S3 sin salir a Internet.
- El **Data Processing Role** es el rol que asumirán esos futuros servicios de procesamiento (por defecto, `lambda.amazonaws.com`) para leer/escribir en el Data Lake, limitado al prefijo `raw/`.
- El **Control Plane Read-Only Role** es un rol de auditoría, pensado para ser asumido por un usuario IAM de confianza, con visibilidad de solo lectura sobre lo que este mismo proyecto crea (VPC e IAM), sin permisos sobre el resto de la cuenta.
- El **bucket del Data Lake** (`coderhouse-datalake-raw-prueba-semana1`), creado en una práctica previa del curso, **no es gestionado por este proyecto**: solo se referencia su ARN como variable para construir la policy del Data Processing Role.

## 3. Estructura de carpetas

```text
project/
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── identity/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       └── backend.tf
│
├── .gitignore
├── .terraform.lock.hcl
├── README.md
└── PLAN_OUTPUT.md
```

## 4. Requisitos previos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configurado con credenciales válidas
- Una cuenta de AWS con permisos para gestionar S3, DynamoDB, VPC e IAM

## 5. Configuración de AWS

Verificar que las credenciales activas correspondan a la cuenta correcta antes de ejecutar cualquier comando:

```bash
aws sts get-caller-identity
```

Este proyecto fue desarrollado y probado sobre la cuenta `426143721475`, región `us-east-1`.

## 6. Bootstrap del backend

El backend remoto de Terraform (bucket S3 + tabla DynamoDB) **no lo crea Terraform**: debe existir antes de `terraform init`, y se crea manualmente vía AWS CLI.

**Bucket S3** (`coderhouse-terraform-state-mauro-dev`):

```bash
aws s3api create-bucket --bucket coderhouse-terraform-state-mauro-dev --region us-east-1
aws s3api put-bucket-versioning --bucket coderhouse-terraform-state-mauro-dev --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket coderhouse-terraform-state-mauro-dev --server-side-encryption-configuration file://encryption.json
aws s3api put-public-access-block --bucket coderhouse-terraform-state-mauro-dev --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

**Tabla DynamoDB** (`coderhouse-terraform-locks`), para el locking del state:

```bash
aws dynamodb create-table \
  --table-name coderhouse-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Este backend es independiente del bucket del Data Lake (`coderhouse-datalake-raw-prueba-semana1`); nunca se mezclan.

## 7. Inicialización de Terraform

Parado dentro de `environments/dev/`:

```bash
terraform init
```

Terraform se conecta al backend S3 configurado en `backend.tf`, descarga el provider de AWS (`~> 5.0`) y prepara los módulos `network` e `identity`.

## 8. Ejecución de `terraform validate`

```bash
terraform validate
```

Revisa que la sintaxis HCL sea correcta y que las referencias entre variables, módulos y outputs sean consistentes (sin verificar aún contra el estado real de AWS).

## 9. Ejecución de `terraform plan`

```bash
terraform plan
```

Compara la configuración declarada contra el estado remoto actual y muestra qué recursos se crearían, modificarían o destruirían, sin aplicar ningún cambio todavía.

## 10. Ejecución de `terraform apply`

```bash
terraform apply
```

Aplica los cambios mostrados en el plan. Terraform pide confirmación explícita (`yes`) antes de crear recursos reales en AWS.

## 11. Recursos creados

**Módulo `network`:**
- 1 VPC (`aws_vpc`)
- 2 subnets privadas en distintas Availability Zones (`aws_subnet`)
- 2 route tables privadas, una por subnet (`aws_route_table`)
- 2 asociaciones de route table (`aws_route_table_association`)
- 1 S3 Gateway Endpoint asociado a ambas route tables (`aws_vpc_endpoint`)

**Módulo `identity`:**
- 1 rol IAM de procesamiento de datos (`aws_iam_role.data_processing`) + policy custom (List/Get/PutObject restringido a un prefijo) + attachment
- 1 rol IAM de solo lectura para auditoría (`aws_iam_role.control_plane_readonly`) + policy custom de solo lectura + attachment

## 12. Outputs

| Output | Descripción |
|---|---|
| `vpc_id` | ID de la VPC creada |
| `private_subnet_ids` | IDs de las dos subnets privadas |
| `data_processing_role_arn` | ARN del rol para futuros servicios de procesamiento |
| `control_plane_role_arn` | ARN del rol de solo lectura para auditoría |

## 13. Consideraciones de seguridad

- Las subnets privadas no tienen ruta hacia un Internet Gateway ni NAT Gateway: sin acceso directo a Internet.
- El acceso a S3 desde la red privada se realiza exclusivamente vía Gateway Endpoint, sin salir a Internet.
- El Data Processing Role sigue el principio de mínimo privilegio: solo `s3:ListBucket`, `s3:GetObject` y `s3:PutObject`, restringidos al prefijo `raw/` del bucket del Data Lake.
- El Control Plane Read-Only Role no tiene permisos de escritura ni administración; su alcance está limitado a describir/leer los recursos que este mismo proyecto crea (VPC e IAM), en vez de usar una policy administrada de alcance amplio (`ReadOnlyAccess`), para mantener el mínimo privilegio.
- El state de Terraform se almacena cifrado (SSE) en S3, con versionado y bloqueo de acceso público, y su modificación concurrente está protegida por locking en DynamoDB.
- No se hardcodean credenciales ni secretos en ningún archivo versionado.

## 14. Cómo reutilizar los módulos para otro ambiente (ej. `prod`)

1. Crear una nueva carpeta `environments/prod/` con la misma estructura que `environments/dev/` (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `backend.tf`).
2. En `backend.tf`, usar una `key` distinta (ej. `pe1/prod/terraform.tfstate`) dentro del mismo bucket de backend, o un backend separado si se prefiere aislar completamente los states.
3. En `variables.tf`, ajustar los valores según el nuevo ambiente (`environment = "prod"`, `vpc_cidr` distinto para evitar solapamiento si ambos se conectan alguna vez, etc.).
4. Los módulos `network` e `identity` no requieren ninguna modificación: fueron diseñados para recibir toda su configuración por variables.

---

**Nota:** este proyecto es parte de un curso académico y no gestiona el bucket del Data Lake (`coderhouse-datalake-raw-prueba-semana1`), que fue creado en una práctica previa y se referencia únicamente por su ARN.