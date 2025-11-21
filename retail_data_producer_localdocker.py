from confluent_kafka import Producer
import json, random, time
from datetime import datetime
import argparse

# -------------------------------
# Parsear parámetros
# -------------------------------
parser = argparse.ArgumentParser(description="Synthetic retail Kafka producer")
parser.add_argument("--num-users", type=int, default=10, help="Número de usuarios")
parser.add_argument("--interval", type=float, default=10, help="Tiempo medio entre envíos (segundos)")
parser.add_argument("--conversion-prob", type=float, default=0.3, help="Probabilidad de que un click genere una orden")
args = parser.parse_args()

# -------------------------------
# Configurar productor Confluent
# -------------------------------
producer = Producer({
    "bootstrap.servers": "localhost:9092,localhost:9094,localhost:9096"
})

def send(topic, value):
    producer.produce(topic, json.dumps(value).encode("utf-8"))
    producer.flush()

users = [f"user_{i}" for i in range(1, args.num_users + 1)]
pages = ["home", "product", "cart", "search", "checkout"]
referrers = ["google", "facebook", "newsletter", "direct"]

# -------------------------------
# Log al inicio
# -------------------------------
print(f"[{datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')}] Producer iniciado")
print(f"Número de usuarios: {args.num_users}")
print(f"Intervalo medio entre envíos: {args.interval} segundos")
print(f"Probabilidad de conversión por click: {args.conversion_prob}")
print("Usuarios:", users)
print("------")

# -------------------------------
# Loop principal
# -------------------------------
while True:
    u = random.choice(users)
    ts_str = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
    ref = random.choice(referrers)

    # Click event
    click_event = {
        "username": u,
        "ts": ts_str,
        "page": random.choice(pages),
        "referrer": ref,
        "session_id": f"session_{random.randint(1000, 9999)}"
    }
    send("retail_clicks", click_event)

    # Decidir si generar orden
    if random.random() < args.conversion_prob:
        order_event = {
            "username": u,
            "ts": ts_str,
            "order_id": random.randint(1000, 9999),
            "items": random.randint(1, 5),
            "referrer": ref   # <-- añadimos referrer aquí
        }
        send("retail_orders", order_event)

        # Payment relacionado
        amount_value = round(random.uniform(5, 100), 2)
        payment_event = {
            "username": u,
            "ts": ts_str,
            "amount": float(f"{amount_value:.2f}"),
            "referrer": ref   # <-- también añadimos referrer
        }
        send("retail_payments", payment_event)

    else:
        order_event = None
        payment_event = None

    # Log
    print(f"[{ts_str}] Click enviado para {u}: {click_event}")
    if order_event:
        print(f"  Order: {order_event}")
        print(f"  Payment: {payment_event}")
    else:
        print("  No se generó ni orden ni pago")

    # Intervalo variable
    sleep_time = random.uniform(args.interval * 0.5, args.interval * 1.5)
    time.sleep(sleep_time)
