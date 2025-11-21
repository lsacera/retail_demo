#!/bin/bash
# Script para copiar JARs y SQL a los contenedores Flink correspondientes
# esto automatiza los jars de librerías y todas las consultas de flink
# Debe ejecutarse desde el directorio donde están los JARs y el SQL

# Nombres de los contenedores
JOBMANAGER_CONTAINER=flink-jobmanager
TASKMANAGER_CONTAINER=flink-taskmanager
SQLCLIENT_CONTAINER=flink-sql-client

# Archivos a copiar
JARS=(
  flink-connector-jdbc-3.3.0-1.19.jar
  flink-connector-jdbc-postgres-3.3.0-1.19.jar
  postgresql-42.7.8.jar
)
SQL=flink-retail.sql

echo "[INFO] Copiando JARs a JobManager..."
for jar in "${JARS[@]}"; do
  docker cp "$jar" "$JOBMANAGER_CONTAINER":/opt/flink/lib/
done

echo "[INFO] Copiando JARs a TaskManager..."
for jar in "${JARS[@]}"; do
  docker cp "$jar" "$TASKMANAGER_CONTAINER":/opt/flink/lib/
done

echo "[INFO] Copiando JARs a SQL Client..."
for jar in "${JARS[@]}"; do
  docker cp "$jar" "$SQLCLIENT_CONTAINER":/opt/flink/lib/
done

echo "[INFO] Copiando SQL a SQL Client..."
docker cp "$SQL" "$SQLCLIENT_CONTAINER":/opt/

echo "[INFO] Copia completada."
