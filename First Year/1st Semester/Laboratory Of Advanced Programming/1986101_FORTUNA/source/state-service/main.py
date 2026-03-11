import json
import threading
import time

import pika
import uvicorn
from fastapi import FastAPI

RABBITMQ_HOST = "rabbitmq"
EXCHANGE_NAME = "sensor_events"
QUEUE_NAME = "state_service_queue"

app = FastAPI(title="State Service")

# stato in memoria
latest_state = {}


def update_state(event: dict) -> None:
    source_name = event.get("source_name")
    if not source_name:
        return

    latest_state[source_name] = event


def wait_for_rabbitmq():
    while True:
        try:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host=RABBITMQ_HOST)
            )
            print("RabbitMQ ready")
            return connection
        except pika.exceptions.AMQPConnectionError:
            print("Waiting for RabbitMQ...")
            time.sleep(2)


def consume_events():
    connection = wait_for_rabbitmq()
    channel = connection.channel()

    # exchange dell'ingestion-service
    channel.exchange_declare(
        exchange=EXCHANGE_NAME,
        exchange_type="fanout"
    )

    # queue del State Service
    channel.queue_declare(queue=QUEUE_NAME)
    channel.queue_bind(exchange=EXCHANGE_NAME, queue=QUEUE_NAME)

    print(f"Bound queue '{QUEUE_NAME}' to exchange '{EXCHANGE_NAME}'")

    def callback(ch, method, properties, body):
        try:
            event = json.loads(body)
            update_state(event)
            print(f"State updated: {event['source_name']}")
        except Exception as e:
            print("Error processing message:", e)

    channel.basic_consume(
        queue=QUEUE_NAME,
        on_message_callback=callback,
        auto_ack=True
    )

    print("State Service is consuming events...")
    channel.start_consuming()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/state/sensors")
def get_all_state():
    return latest_state


@app.get("/state/sensors/{source_name}")
def get_sensor_state(source_name: str):
    if source_name not in latest_state:
        return {"error": "sensor not found"}
    return latest_state[source_name]


if __name__ == "__main__":
    consumer_thread = threading.Thread(target=consume_events, daemon=True)
    consumer_thread.start()

    uvicorn.run(app, host="0.0.0.0", port=8001)