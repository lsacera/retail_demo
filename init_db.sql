-- init_db.sql

-- Creación de la base de datos (solo si no existe y si el usuario 'grafana' tiene permisos para crear bases de datos)
-- Nota: Si usas una imagen Docker estándar, probablemente necesites crear la DB antes de la primera conexión.
-- Si el comando docker exec en el script ya se conecta a 'retail', esta línea podría no ser necesaria.
-- Si la DB no existe, el comando \c retail fallará.

-- Intentaremos crear la base de datos si el entorno lo permite
CREATE DATABASE retail;

-- Conexión a la nueva base de datos
\c retail

-- Eliminamos las tablas si ya existen (opcional, útil para pruebas)
DROP TABLE IF EXISTS retail_agg_orders_per_user;
DROP TABLE IF EXISTS retail_sales_revenue;
DROP TABLE IF EXISTS retail_conversion_rate;
DROP TABLE IF EXISTS retail_avg_order_value;
DROP TABLE IF EXISTS conversion_by_referrer;


-- Creación de Tablas
--------------------

CREATE TABLE retail_agg_orders_per_user (
    username TEXT PRIMARY KEY,
    total_orders BIGINT
);

CREATE TABLE retail_sales_revenue (
    username TEXT PRIMARY KEY,
    total_amount DOUBLE PRECISION
);

CREATE TABLE retail_conversion_rate (
    username TEXT PRIMARY KEY,
    clicks BIGINT,
    orders BIGINT,
    conversion_rate DOUBLE PRECISION
);

CREATE TABLE retail_avg_order_value (
    username TEXT PRIMARY KEY,
    avg_order DOUBLE PRECISION
);

CREATE TABLE conversion_by_referrer (
    referrer TEXT PRIMARY KEY,
    clicks BIGINT,
    orders BIGINT,
    conversion_rate DOUBLE PRECISION
);