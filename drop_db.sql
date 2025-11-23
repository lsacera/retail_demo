-- drop_db.sql

-- 1. Conectarse a la base de datos por defecto 'postgres'
-- Es necesario para eliminar la base de datos 'retail'.
\c postgres

-- 2. Terminar cualquier conexión activa a la base de datos 'retail'
-- Esto es crucial, ya que PostgreSQL no permite eliminar una base de datos que está en uso.
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'retail';

-- 3. Eliminar la base de datos 'retail' (si existe)
DROP DATABASE IF EXISTS retail;