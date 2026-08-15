# Segunda Pre-entrega — Ingeniería de Datos (Coderhouse)
## Pipeline de Ingesta en Tiempo Real con Kinesis + Firehose (Capa Bronze)

**Alumno:** Mauro
**Módulo:** Semana 2 — Arquitectura de Data Lake con Terraform en AWS

---

## 1. Descripción general

Este proyecto implementa, mediante Terraform modularizado, la infraestructura de ingesta en tiempo real de un Data Lake en AWS. El flujo de datos es:

```
Productor (Python/Boto3) → Kinesis Data Stream → Kinesis Data Firehose → S3 (Capa Bronze)
```

El objetivo de esta etapa es dejar la infraestructura como código (IaC) validada, modular y libre de errores sintácticos, lista para desplegarse en cuanto la cuenta de AWS quede habilitada (ver Nota para el tutor, punto 6).

---

## 2. Estructura del proyecto

```
Semana 2/
├── environments/
│   └── dev/
│       └── main.tf        # Provider AWS (us-east-1), bucket S3 Bronze, instancia del módulo kinesis, outputs
├── modules/
│   └── kinesis/
│       ├── main.tf        # Kinesis Data Stream + Firehose + Alarmas CloudWatch
│       ├── variables.tf
│       └── outputs.tf
└── scripts/
    └── producer.py         # Simulador de ingesta con Boto3
```

- **environments/dev/main.tf**: configura el proveedor AWS en `us-east-1`, crea el bucket S3 del Data Lake (`coderhouse-datalake-mauro-dev`) para la capa Bronze, instancia el módulo `kinesis` pasándole las variables correspondientes, y expone los outputs (`stream_arn`, `firehose_arn`).
- **modules/kinesis/**: módulo reutilizable que define:
  - Un **Kinesis Data Stream** en modo `PROVISIONED` con **2 shards**.
  - Un **Kinesis Data Firehose** con destino `extended_s3`, compresión **GZIP** y buffering de desarrollo (5 MB / 60 s).
  - Prefijos dinámicos por fecha en S3 (`ingesta/year=!{timestamp:yyyy}/...`).
  - **2 alarmas de CloudWatch** para monitorear throttling de lectura y escritura sobre el stream.
- **scripts/producer.py**: script en Python (Boto3) que simula la inyección de 100 registros al stream, usando un UUID dinámico como `PartitionKey` en cada `put_record`.

---

## 3. Cálculo de capacidad: justificación de los 2 shards

Kinesis Data Streams, en modo `PROVISIONED`, dimensiona la capacidad de un stream en función del número de shards. Cada shard individual soporta, como límite de servicio de AWS:

- **Escritura:** hasta 1 MB/s (o 1.000 registros/s), lo que ocurra primero.
- **Lectura:** hasta 2 MB/s.

El requisito de la consigna es soportar un throughput de ingesta de **2 MB/s**. El cálculo de shards necesarios se obtiene de:

```
shards_necesarios = ceil( throughput_requerido_MB_s / capacidad_escritura_por_shard_MB_s )
shards_necesarios = ceil( 2 MB/s / 1 MB/s )
shards_necesarios = 2
```

Por eso el módulo fija `shard_count = 2`: con dos shards en paralelo se cubre exactamente la capacidad de escritura de 2 MB/s exigida, dejando además margen de lectura de hasta 4 MB/s combinados (2 MB/s por shard), suficiente para que Firehose consuma el stream sin generar throttling.

Este valor está reflejado y confirmado en la salida real de `terraform plan` (ver punto 5):

```
+ shard_count = 2
```

---

## 4. Mitigación del problema de "Hot Shards"

Un **Hot Shard** ocurre cuando una `PartitionKey` mal distribuida concentra la mayoría de los registros en un único shard, saturando su capacidad mientras los demás shards quedan subutilizados. Kinesis asigna cada registro a un shard aplicando una función hash sobre la `PartitionKey`, por lo que la distribución de las claves determina directamente el balanceo de carga.

**Solución implementada en `scripts/producer.py`:**

En lugar de usar una clave fija o de baja cardinalidad (por ejemplo, un `id_producto` repetido o un valor constante), el script genera un **UUID dinámico por cada registro** y lo utiliza como `PartitionKey`:

```python
import uuid

partition_key = str(uuid.uuid4())

client.put_record(
    StreamName=STREAM_NAME,
    Data=json.dumps(record),
    PartitionKey=partition_key
)
```

Al ser un valor prácticamente aleatorio y de altísima cardinalidad, el hash resultante se distribuye de forma uniforme entre los 2 shards disponibles, evitando por diseño la concentración de tráfico en uno solo. Esta es una mitigación **preventiva a nivel de arquitectura del productor**, no un ajuste posterior de infraestructura.

---

## 5. Validación técnica (sin despliegue físico)

Debido a una restricción administrativa de la cuenta de AWS (ver Nota al tutor), no fue posible ejecutar `terraform apply`. Como validación alternativa, se ejecutó `terraform plan` desde `environments/dev`, obteniendo una salida limpia y sin errores:

```
Plan: 6 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + firehose_arn = (known after apply)
  + stream_arn   = (known after apply)
```

La captura de pantalla de esta ejecución se adjunta como evidencia (`terraform_plan_evidence.png`). Este resultado confirma que:

- No hay errores de sintaxis (HCL) en ninguno de los módulos.
- Las referencias entre `environments/dev` y `modules/kinesis` están correctamente resueltas (variables, outputs).
- Los 6 recursos planificados (stream, firehose, bucket S3, 2 alarmas de CloudWatch y el rol/policy asociado) son consistentes con el diseño de arquitectura propuesto.

---

## 6. Comando de AWS CLI: envío manual de un evento de prueba

Para probar el stream de forma aislada, sin depender del script `producer.py`, se puede enviar un único registro manualmente vía AWS CLI:

```bash
aws kinesis put-record \
  --stream-name clicks-ecommerce-dev \
  --partition-key "$(uuidgen)" \
  --data '{"evento": "click_prueba", "usuario_id": "test-001", "timestamp": "2026-08-11T12:00:00Z"}' \
  --region us-east-1
```

> Nota: `--data` se envía en texto plano; el AWS CLI se encarga de codificarlo en Base64 automáticamente antes de transmitirlo al stream.

---

## 7. Nota aclaratoria para el tutor

Durante la ejecución de `terraform apply` en la cuenta personal de AWS utilizada para esta pre-entrega, se produjeron los siguientes errores administrativos, **no relacionados con el código de Terraform**:

- `SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service`
- `AccessDenied` al intentar crear roles de IAM.

Al verificar en la consola web de AWS, la plataforma confirmó que la cuenta es **nueva y se encuentra en proceso de verificación/activación completa**, proceso que AWS indica puede demorar hasta 24 horas y que es completamente ajeno a la lógica o sintaxis del código entregado.

Por este motivo, **no fue posible completar el despliegue físico de la infraestructura ni ejecutar `producer.py` contra un stream real** dentro del plazo de esta entrega.

Como evidencia de que la arquitectura, la modularización y la sintaxis cumplen con lo solicitado en la consigna, se adjunta la salida exitosa de `terraform plan` (punto 5 de este documento), que muestra **6 recursos a agregar, 0 cambios, 0 destrucciones**, sin ningún error de validación. Esto demuestra que el plan de ejecución es válido y que, en cuanto la cuenta de AWS quede habilitada, el `terraform apply` se ejecutará sin necesidad de modificar el código presentado.

Quedo a disposición para hacer una demo en vivo del despliegue apenas la cuenta de AWS esté activa.

---

## 8. Autor

Mauro — Curso de Ingeniería de Datos, Coderhouse.
