#!/bin/bash

# Variables de configuración
DB_CONTAINER="postgres"
DB_USER="grafana"
DB_PASSWORD="grafana"
SQL_FILE="init_db.sql"

echo "⏳ Waiting for PostgresSQL to be ready..."
# Simple espera, puede que necesites un mecanismo más robusto para entornos de producción
sleep 10 

echo "🚀 Executing script SQL ($SQL_FILE) in the db container $DB_CONTAINER..."

# Copiar el archivo SQL dentro del contenedor
docker cp "$SQL_FILE" "$DB_CONTAINER":/tmp/"$SQL_FILE"

# Ejecutar el archivo SQL usando docker exec
# Usamos <<-EOF para que psql ejecute un comando simple que ejecuta el fichero
# Pasamos la contraseña como variable de entorno
docker exec \
  -e PGPASSWORD="$DB_PASSWORD" \
  -it "$DB_CONTAINER" \
  psql -U "$DB_USER" -d postgres -f /tmp/"$SQL_FILE"

# El comando 'psql -d postgres' se conecta a la base de datos 'postgres' por defecto 
# para poder ejecutar 'CREATE DATABASE retail;' primero. 
# El resto de los comandos se ejecutan luego de la sentencia \c retail dentro del fichero SQL.

echo "✅ Database init and table creation completed."