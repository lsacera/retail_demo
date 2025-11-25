#!/bin/bash

# Variables de configuración
DB_CONTAINER="postgres"
DB_USER="grafana"
DB_PASSWORD="grafana"
SQL_FILE="drop_db.sql"

echo "🗑️ Initializaing dabase removal..."
echo "---------------------------------------------------"

# Copiar el archivo SQL dentro del contenedor
docker cp "$SQL_FILE" "$DB_CONTAINER":/tmp/"$SQL_FILE"

echo "Executing script SQL ($SQL_FILE) in the db container $DB_CONTAINER..."

# Ejecutar el archivo SQL usando docker exec
# Pasamos la contraseña como variable de entorno
docker exec \
  -e PGPASSWORD="$DB_PASSWORD" \
  -it "$DB_CONTAINER" \
  psql -U "$DB_USER" -d postgres -f /tmp/"$SQL_FILE"

echo "✅ Database 'retail' removed successfully."