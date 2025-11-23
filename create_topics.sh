#!/bin/bash

# Array que contiene los nombres de todos los tópicos a crear
TOPICS=(
  retail_agg_orders_per_user
  retail_sales_revenue
  retail_conversion_rate
  retail_avg_order_value
  retail_clicks
  retail_orders
  retail_payments
  clicks_per_referrer
  orders_per_referrer
  conversion_by_referrer
  clicks_per_user
  orders_per_user
)

# Configuración común
BROKER_CONTAINER="broker"
BOOTSTRAP_SERVER="broker:29092"
PARTITIONS=3
REPLICATION_FACTOR=1

echo "🚀 Iniciando la creación de tópicos de Kafka..."
echo "---"

# Bucle For para iterar sobre el array TOPICS
for topic in "${TOPICS[@]}"; do
  echo "[INFO] Creando tópico: $topic"
  
  # Ejecuta el comando docker exec para crear el tópico
  docker exec -it "$BROKER_CONTAINER" kafka-topics \
    --create \
    --topic "$topic" \
    --partitions "$PARTITIONS" \
    --replication-factor "$REPLICATION_FACTOR" \
    --bootstrap-server "$BOOTSTRAP_SERVER"
    
  # Opcional: Pausa breve para mejor lectura
  sleep 0.5
done

echo "---"
echo "✅ Creación de todos los tópicos completada."