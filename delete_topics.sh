#!/bin/bash

# Array que contiene los nombres de todos los tópicos a eliminar
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

echo "🗑️ Iniciando la eliminación de tópicos de Kafka..."
echo "---"

# Bucle For para iterar sobre el array TOPICS
for topic in "${TOPICS[@]}"; do
  echo "[INFO] Eliminando tópico: $topic"
  
  # Ejecuta el comando docker exec para eliminar el tópico
  docker exec -it "$BROKER_CONTAINER" kafka-topics \
    --delete \
    --topic "$topic" \
    --bootstrap-server "$BOOTSTRAP_SERVER"
    
  # Opcional: Pausa breve para mejor lectura
  sleep 0.5
done

echo "---"
echo "✅ Eliminación de todos los tópicos solicitada."
echo "⚠️ Nota: En configuraciones por defecto, Kafka solo marca los tópicos como eliminados."
echo "       El borrado real puede tardar, dependiendo de la configuración 'delete.topic.enable=true' del broker."