import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, window, avg
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType, TimestampType

# 1. VARIABLES DE ENTORNO ESTÁNDAR DE LA CLASE
KAFKA_SERVER = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
TOPIC_NAME = os.getenv('KAFKA_TOPIC', 'urban_sensors')

# 2. INICIALIZACIÓN BÁSICA DE SPARK (TAL CUAL LA CLASE)
spark = SparkSession.builder \
    .appName("MonitoreoDistribuidoraStreaming") \
    .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1") \
    .getOrCreate()

# Mantener la consola limpia mostrando solo errores
spark.sparkContext.setLogLevel("ERROR")

# 3. ESQUEMA DE DATOS REQUERIDO POR LA CONSIGNA
esquema_camioneta = StructType([
    StructField("sensor_id", StringType(), True),         
    StructField("temperature", DoubleType(), True),       
    StructField("humidity", DoubleType(), True),          
    StructField("air_quality_index", IntegerType(), True), 
    StructField("timestamp", TimestampType(), True)
])

# 4. LECTURA DEL STREAM DE KAFKA
df_kafka = spark.readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", KAFKA_SERVER) \
    .option("subscribe", TOPIC_NAME) \
    .load()

# 5. PARSEO DEL JSON BINARIO
df_parseado = df_kafka.selectExpr("CAST(value AS STRING) as json_str") \
    .select(from_json(col("json_str"), esquema_camioneta).alias("datos")) \
    .select("datos.*")

# 6. PROCESAMIENTO: VENTANA OBLIGATORIA DE 1 MINUTO Y PROMEDIOS
df_analisis = df_parseado \
    .withWatermark("timestamp", "2 minutes") \
    .groupBy(
        window(col("timestamp"), "1 minute"),
        col("sensor_id").alias("camioneta_id")
    ) \
    .agg(
        avg("temperature").alias("promedio_monto_entregado"),
        avg("air_quality_index").alias("promedio_nivel_combustible")
    )

# 7. SALIDA POR CONSOLA SIN CHEKPOINTS EXTRAÑOS (PARA DESARROLLO LOCAL)
query = df_analisis.writeStream \
    .outputMode("complete") \
    .format("console") \
    .option("truncate", "false") \
    .start()

query.awaitTermination()
