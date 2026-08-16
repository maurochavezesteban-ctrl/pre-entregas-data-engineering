import json
import time
import random
import os
from datetime import datetime
from kafka import KafkaProducer

# 1. LECTURA DE CONFIGURACIÓN DE KUBERNETES (CONFIGMAP)
KAFKA_SERVER = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
TOPIC_NAME = os.getenv('KAFKA_TOPIC', 'urban_sensors')

# 2. INICIALIZACIÓN DEL PRODUCTOR
producer = KafkaProducer(
    bootstrap_servers=[KAFKA_SERVER],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Las 3 camionetas de la distribuidora repartiendo en almacenes de cercanía
camionetas = ['camioneta_01', 'camioneta_02', 'camioneta_03']

# Estado inicial simulado: montos acumulados, nafta y almacenes visitados
estado_viaje = {
    c: {"monto": 0, "combustible": 100.0, "almacenes": 0} for c in camionetas
}

print(f"🚛 Productor de Logística Activo (Almacenes de Cercanía). Monitoreando 3 camionetas...")

try:
    while True:
        # Una camioneta reporta que llegó a una nueva cuadra / almacén
        camioneta_id = random.choice(camionetas)
        
        # Simulación de reparto rápido (avanza de a 1 almacén por reporte)
        if estado_viaje[camioneta_id]["almacenes"] < 40: # Máximo de almacenes en el recorrido total
            estado_viaje[camioneta_id]["almacenes"] += 1
            # Cada almacén de cercanía compra entre $4,000 y $12,000 en mercadería
            estado_viaje[camioneta_id]["monto"] += random.randint(4000, 12000)
            # Consumo menor de combustible por estar a una cuadra de distancia
            estado_viaje[camioneta_id]["combustible"] -= round(random.uniform(0.1, 0.4), 2)
        else:
            # Al terminar el recorrido del día, reinicia la simulación
            estado_viaje[camioneta_id] = {"monto": 0, "combustible": 100.0, "almacenes": 0}

        # Estructura JSON mapeada estratégicamente para cumplir la consigna del profesor
        payload = {
            "sensor_id": camioneta_id, 
            "temperature": float(estado_viaje[camioneta_id]["monto"]),          # Monto acumulado en ARS
            "humidity": float(estado_viaje[camioneta_id]["almacenes"]),         # Cantidad de almacenes visitados
            "air_quality_index": int(estado_viaje[camioneta_id]["combustible"]), # Nivel de combustible %
            "timestamp": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        # Publicación balanceada usando la clave de la camioneta
        producer.send(
            TOPIC_NAME, 
            key=camioneta_id.encode('utf-8'), 
            value=payload
        )
        
        print(f"📦 Reporte -> {camioneta_id} | Almacenes Visitados: {payload['humidity']} | Total Facturado: ${payload['temperature']} | Combustible: {payload['air_quality_index']}%")
        
        # Mandamos un reporte rápido cada 0.5 segundos para llenar la ventana de 1 minuto de Spark con mucha data
        time.sleep(0.5) 
        
except KeyboardInterrupt:
    print("Deteniendo monitoreo de choferes...")
finally:
    producer.flush()
