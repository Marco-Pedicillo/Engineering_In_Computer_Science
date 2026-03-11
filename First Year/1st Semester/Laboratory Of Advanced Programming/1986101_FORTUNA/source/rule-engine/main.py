import json
import time

import pika
import psycopg2
import requests

RABBITMQ_HOST = "rabbitmq"
EXCHANGE_NAME = "sensor_events"
QUEUE_NAME = "rule_engine_queue"

DB_HOST = "postgres"
DB_NAME = "mars_rules"
DB_USER = "postgres"
DB_PASSWORD = "postgres"

SIMULATOR_URL = "http://mars-simulator:8080"


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


def wait_for_postgres():
    while True:
        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                dbname=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            print("Postgres ready")
            return conn
        except Exception:
            print("Waiting for Postgres...")
            time.sleep(2)


def wait_for_simulator():
    while True:
        try:
            response = requests.get(f"{SIMULATOR_URL}/health", timeout=5)
            if response.status_code == 200:
                print("Simulator ready")
                return
        except Exception:
            pass

        print("Waiting for simulator...")
        time.sleep(2)


def create_rules_table(conn):
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS rules (
                id SERIAL PRIMARY KEY,
                source_name VARCHAR(100) NOT NULL,
                metric_name VARCHAR(100) NOT NULL,
                operator VARCHAR(5) NOT NULL,
                threshold_value FLOAT NOT NULL,
                actuator_name VARCHAR(100) NOT NULL,
                target_state VARCHAR(10) NOT NULL,
                enabled BOOLEAN DEFAULT TRUE
            );
        """)
        conn.commit()


def fetch_rules_for_source(conn, source_name):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT source_name, metric_name, operator, threshold_value,
                   actuator_name, target_state
            FROM rules
            WHERE enabled = TRUE AND source_name = %s
        """, (source_name,))
        rows = cur.fetchall()

    rules = []
    for row in rows:
        rules.append({
            "source_name": row[0],
            "metric_name": row[1],
            "operator": row[2],
            "threshold_value": row[3],
            "actuator_name": row[4],
            "target_state": row[5]
        })
    return rules


def evaluate_rule(value, operator, threshold):
    if operator == ">":
        return value > threshold
    if operator == "<":
        return value < threshold
    if operator == ">=":
        return value >= threshold
    if operator == "<=":
        return value <= threshold
    if operator == "=":
        return value == threshold
    return False


def trigger_actuator(actuator_name, target_state):
    url = f"{SIMULATOR_URL}/api/actuators/{actuator_name}"
    payload = {"state": target_state}

    response = requests.post(url, json=payload, timeout=5)
    response.raise_for_status()

    print(f"Actuator triggered: {actuator_name} -> {target_state}")


def process_event(conn, event):
    source_name = event.get("source_name")
    metrics = event.get("metrics", [])

    if not source_name or not metrics:
        return

    rules = fetch_rules_for_source(conn, source_name)

    if not rules:
        print(f"No rules for {source_name}")
        return

    for rule in rules:
        for metric in metrics:
            if metric["name"] != rule["metric_name"]:
                continue

            value = metric["value"]
            threshold = rule["threshold_value"]
            operator = rule["operator"]

            if evaluate_rule(value, operator, threshold):
                print(
                    f"Rule matched: {source_name}.{metric['name']} "
                    f"{operator} {threshold}"
                )
                try:
                    trigger_actuator(
                        rule["actuator_name"],
                        rule["target_state"]
                    )
                except Exception as e:
                    print("Actuator error:", e)


def main():
    wait_for_simulator()
    db_conn = wait_for_postgres()
    create_rules_table(db_conn)

    connection = wait_for_rabbitmq()
    channel = connection.channel()

    channel.exchange_declare(
        exchange=EXCHANGE_NAME,
        exchange_type="fanout"
    )

    channel.queue_declare(queue=QUEUE_NAME)
    channel.queue_bind(exchange=EXCHANGE_NAME, queue=QUEUE_NAME)

    print(f"Bound queue '{QUEUE_NAME}' to exchange '{EXCHANGE_NAME}'")

    def callback(ch, method, properties, body):
        try:
            event = json.loads(body)
            print("Received event:", event["source_name"])
            process_event(db_conn, event)
        except Exception as e:
            print("Error processing event:", e)

    channel.basic_consume(
        queue=QUEUE_NAME,
        on_message_callback=callback,
        auto_ack=True
    )

    print("Rule Engine is consuming events...")
    channel.start_consuming()


if __name__ == "__main__":
    main()