/*
Lo primero es crear las tablas que me hacen falta 
*/
CREATE TABLE retail_agg_orders_per_user (
    username STRING,
    total_orders BIGINT,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'retail_agg_orders_per_user',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'key.format' = 'json',
    'value.format' = 'json'
);

CREATE TABLE retail_orders (
    username STRING,
    ts TIMESTAMP(3),
    order_id BIGINT,
    items INT,
    referrer STRING,
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'retail_orders',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'properties.group.id' = 'flink_orders',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

CREATE TABLE retail_clicks (
    username STRING,
    ts TIMESTAMP(3),
    page STRING,
    referrer STRING,
    session_id STRING,
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'retail_clicks',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'properties.group.id' = 'flink_clicks',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

/*
Se rellena la tabla con los datos en tiempo real.
*/
INSERT INTO retail_agg_orders_per_user
SELECT
    username,
    COUNT(order_id) AS total_orders
FROM retail_orders
WHERE username IS NOT NULL
GROUP BY username;

/*
Ahora el total que se gasta cada usuario en sus compras.
*/
CREATE TABLE retail_sales_revenue (
    username STRING,
    total_amount DOUBLE,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'retail_sales_revenue',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'key.format' = 'json',
    'value.format' = 'json'
);

/*
Los pagos
*/
CREATE TABLE retail_payments (
    username STRING,
    ts STRING,
    amount DOUBLE
) WITH (
    'connector' = 'kafka',
    'topic' = 'retail_payments',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json'
);

/*
Se procesan las ganancias
*/
INSERT INTO retail_sales_revenue
SELECT
    username,
    SUM(amount) AS total_amount
FROM retail_payments
WHERE username IS NOT NULL
GROUP BY username;

/*
CONVERSION RATE POR USUARIO
*/
-- paso 1: clicks por usuario
CREATE TABLE clicks_per_user (
    username STRING,
    clicks BIGINT,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'clicks_per_user',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'key.format' = 'json',
    'value.format' = 'json'
);

INSERT INTO clicks_per_user
SELECT
    username,
    COUNT(*) AS clicks
FROM retail_clicks
WHERE username IS NOT NULL
GROUP BY username;

-- paso 2: ordenes por usuario
CREATE TABLE orders_per_user (
    username STRING,
    orders BIGINT,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'orders_per_user',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'key.format' = 'json',
    'value.format' = 'json'
);

INSERT INTO orders_per_user
SELECT
    username,
    COUNT(*) AS orders
FROM retail_orders
WHERE username IS NOT NULL
GROUP BY username;

-- paso 3: tabla de conversion
CREATE TABLE retail_conversion_rate (
    username STRING,
    clicks BIGINT,
    orders BIGINT,
    conversion_rate DOUBLE,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'retail_conversion_rate',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'key.format' = 'json',
    'value.format' = 'json'
);

INSERT INTO retail_conversion_rate
SELECT
    c.username,
    c.clicks,
    o.orders,
    o.orders / CAST(c.clicks AS DOUBLE) AS conversion_rate
FROM clicks_per_user AS c
LEFT JOIN orders_per_user AS o
ON c.username = o.username;

/*
Ingresos medios por pedido - definición
*/
CREATE TABLE retail_avg_order_value (
    username STRING,
    avg_order DOUBLE,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'upsert-kafka',
    'topic' = 'retail_avg_order_value',
    'properties.bootstrap.servers' = 'broker:29092,broker-2:29092,broker-3:29092',
    'key.format' = 'json',
    'value.format' = 'json'
);

/* 
Proceso de los ingresos medios
*/
INSERT INTO retail_avg_order_value
SELECT
    o.username,
    SUM(p.amount) / COUNT(o.order_id) AS avg_order
FROM retail_orders AS o
JOIN retail_payments AS p
ON o.username = p.username
GROUP BY o.username;

/*
Ahora la parte de referer se queda igual (no usamos 'user' aquí)
*/
--PASO 1: tabla de los clics por usuario, los guardo en el topic 
CREATE TABLE clicks_per_referrer ( 
    referrer STRING, 
    clicks BIGINT, 
    PRIMARY KEY (referrer) NOT ENFORCED 
) WITH ( 
    'connector' = 'upsert-kafka', 
    'topic' = 'clicks_per_referrer', 
    'properties.bootstrap.servers' = 
    'broker:29092,broker-2:29092,broker-3:29092', 
    'key.format' = 'json', 
    'value.format' = 'json' ); 

INSERT INTO clicks_per_referrer 
SELECT 
    referrer, 
    COUNT(*) AS clicks 
FROM retail_clicks 
GROUP BY referrer; 

--PASO 2: Tabla de ordenes agregados por referrer, ojo al topic 
CREATE TABLE orders_per_referrer ( 
    referrer STRING, 
    orders BIGINT, 
    PRIMARY KEY (referrer) NOT ENFORCED
 ) WITH ( 
    'connector' = 'upsert-kafka', 
    'topic' = 'orders_per_referrer', 
    'properties.bootstrap.servers' = 
    'broker:29092,broker-2:29092,broker-3:29092', 
    'key.format' = 'json', 'value.format' = 'json' ); 
    
INSERT INTO orders_per_referrer 
SELECT 
    referrer, 
    COUNT(*) AS orders 
FROM retail_orders 
GROUP BY referrer; 


--PASO 3: tabla final, la conversión por referer (ojo al tópico) 
CREATE TABLE conversion_by_referrer ( 
    referrer STRING, 
    clicks BIGINT, 
    orders BIGINT, 
    conversion_rate DOUBLE, 
    PRIMARY KEY (referrer) NOT ENFORCED 
) WITH ( 
    'connector' = 'upsert-kafka', 
    'topic' = 'conversion_by_referrer', 
    'properties.bootstrap.servers' = 
    'broker:29092,broker-2:29092,broker-3:29092', 
    'key.format' = 'json', 'value.format' = 'json'); 
    
INSERT INTO conversion_by_referrer 
SELECT 
    c.referrer, 
    c.clicks, 
    o.orders, 
    o.orders / CAST(c.clicks AS DOUBLE) AS conversion_rate 
FROM clicks_per_referrer AS c 
JOIN orders_per_referrer AS o 
ON c.referrer = o.referrer;

/*
POSGRES
Persistir los datos en tablas de postgres
*/
-- Conector base para PostgreSQL
CREATE TABLE pg_retail_agg_orders_per_user (
    username STRING,
    total_orders BIGINT,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/retail',
    'table-name' = 'retail_agg_orders_per_user',
    'driver' = 'org.postgresql.Driver',
    'username' = 'grafana',
    'password' = 'grafana'
);

CREATE TABLE pg_retail_sales_revenue (
    username STRING,
    total_amount DOUBLE,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/retail',
    'table-name' = 'retail_sales_revenue',
    'driver' = 'org.postgresql.Driver',
    'username' = 'grafana',
    'password' = 'grafana'
);

CREATE TABLE pg_retail_conversion_rate (
    username STRING,
    clicks BIGINT,
    orders BIGINT,
    conversion_rate DOUBLE,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/retail',
    'table-name' = 'retail_conversion_rate',
    'driver' = 'org.postgresql.Driver',
    'username' = 'grafana',
    'password' = 'grafana'
);

CREATE TABLE pg_retail_avg_order_value (
    username STRING,
    avg_order DOUBLE,
    PRIMARY KEY (username) NOT ENFORCED
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/retail',
    'table-name' = 'retail_avg_order_value',
    'driver' = 'org.postgresql.Driver',
    'username' = 'grafana',
    'password' = 'grafana'
);

CREATE TABLE pg_conversion_by_referrer ( 
    referrer STRING, 
    clicks BIGINT, 
    orders BIGINT, 
    conversion_rate DOUBLE, 
    PRIMARY KEY (referrer) NOT ENFORCED 
) WITH ( 
    'connector' = 'jdbc', 
    'url' = 'jdbc:postgresql://postgres:5432/retail', 
    'table-name' = 'conversion_by_referrer', 
    'driver' = 'org.postgresql.Driver', 
    'username' = 'grafana', 
    'password' = 'grafana' );

-- INSERTs actualizados
INSERT INTO pg_retail_agg_orders_per_user
SELECT * FROM retail_agg_orders_per_user;

INSERT INTO pg_retail_sales_revenue
SELECT * FROM retail_sales_revenue;

INSERT INTO pg_retail_conversion_rate
SELECT * FROM retail_conversion_rate;

INSERT INTO pg_retail_avg_order_value
SELECT * FROM retail_avg_order_value;

INSERT INTO pg_conversion_by_referrer
SELECT * FROM conversion_by_referrer;
