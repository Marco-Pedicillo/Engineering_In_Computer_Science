import json
import threading
import time

import pika
import requests

SIMULATOR_URL = "http://mars-simulator:8080"
RABBITMQ_HOST = "rabbitmq"
EXCHANGE_NAME = "sensor_events"

POLL_INTERVAL = 5


# ---------------------------------------------------
# wait for services
# ---------------------------------------------------

def wait_for_simulator():
    while True:
        try:
            r = requests.get(f"{SIMULATOR_URL}/health", timeout=5)
            if r.status_code == 200:
                print("Simulator ready")
                return
        except Exception:
            pass

        print("Waiting for simulator...")
        time.sleep(2)


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


# ---------------------------------------------------
# simulator REST API
# ---------------------------------------------------

def get_sensor_ids():
    response = requests.get(f"{SIMULATOR_URL}/api/sensors", timeout=10)
    response.raise_for_status()
    data = response.json()
    return data["sensors"]


def get_sensor_data(sensor_id):
    response = requests.get(f"{SIMULATOR_URL}/api/sensors/{sensor_id}", timeout=10)
    response.raise_for_status()
    return response.json()


# ---------------------------------------------------
# telemetry API
# ---------------------------------------------------

def get_telemetry_topics():
    response = requests.get(f"{SIMULATOR_URL}/api/telemetry/topics", timeout=10)
    response.raise_for_status()
    data = response.json()

    # adatta se il simulatore restituisce una chiave diversa
    if isinstance(data, dict) and "topics" in data:
        return data["topics"]

    if isinstance(data, list):
        return data

    return []


# ---------------------------------------------------
# normalization
# ---------------------------------------------------

def normalize_rest_event(sensor_id, payload):
    event = {
        "source_name": sensor_id,
        "timestamp": payload.get("captured_at"),
        "source_type": "rest",
        "metrics": [],
        "status": payload.get("status", "unknown")
    }

    if "metric" in payload:
        event["metrics"].append({
            "name": payload["metric"],
            "value": payload["value"],
            "unit": payload.get("unit")
        })

    elif "measurements" in payload:
        for m in payload["measurements"]:
            event["metrics"].append({
                "name": m["metric"],
                "value": m["value"],
                "unit": m.get("unit")
            })

    elif "pm1_ug_m3" in payload:
        event["metrics"].append({
            "name": "pm1_ug_m3",
            "value": payload["pm1_ug_m3"],
            "unit": "ug/m3"
        })
        event["metrics"].append({
            "name": "pm25_ug_m3",
            "value": payload["pm25_ug_m3"],
            "unit": "ug/m3"
        })
        event["metrics"].append({
            "name": "pm10_ug_m3",
            "value": payload["pm10_ug_m3"],
            "unit": "ug/m3"
        })

    elif "level_pct" in payload:
        event["metrics"].append({
            "name": "level_pct",
            "value": payload["level_pct"],
            "unit": "%"
        })
        event["metrics"].append({
            "name": "level_liters",
            "value": payload["level_liters"],
            "unit": "L"
        })

    return event


def normalize_telemetry_event(topic_name, payload):
    event = {
        "source_name": topic_name,
        "timestamp": payload.get("captured_at") or payload.get("timestamp"),
        "source_type": "telemetry",
        "metrics": [],
        "status": payload.get("status", "unknown")
    }

    if "metric" in payload and "value" in payload:
        event["metrics"].append({
            "name": payload["metric"],
            "value": payload["value"],
            "unit": payload.get("unit")
        })
        return event

    if "measurements" in payload:
        for m in payload["measurements"]:
            event["metrics"].append({
                "name": m.get("metric"),
                "value": m.get("value"),
                "unit": m.get("unit")
            })
        return event

    # fallback generico:
    excluded_keys = {"captured_at", "timestamp", "status", "sensor_id", "topic"}
    for key, value in payload.items():
        if key in excluded_keys:
            continue
        if isinstance(value, (int, float)):
            event["metrics"].append({
                "name": key,
                "value": value,
                "unit": None
            })

    return event


# ---------------------------------------------------
# publish event
# ---------------------------------------------------

def publish_event(channel, event):
    message = json.dumps(event)

    channel.basic_publish(
        exchange=EXCHANGE_NAME,
        routing_key="",
        body=message
    )

    print("Published:", message)


# ---------------------------------------------------
# REST polling loop
# ---------------------------------------------------

def poll_rest_sensors(channel):
    while True:
        try:
            sensors = get_sensor_ids()
            print("REST sensors:", sensors)

            for sensor in sensors:
                try:
                    payload = get_sensor_data(sensor)
                    event = normalize_rest_event(sensor, payload)
                    publish_event(channel, event)
                except Exception as e:
                    print("REST sensor error:", sensor, e)

            print("REST polling cycle completed\n")

        except Exception as e:
            print("REST polling error:", e)

        time.sleep(POLL_INTERVAL)


# ---------------------------------------------------
# telemetry stream loop
# ---------------------------------------------------

def consume_single_topic(topic_name):
    connection = wait_for_rabbitmq()
    channel = connection.channel()

    channel.exchange_declare(
        exchange=EXCHANGE_NAME,
        exchange_type="fanout"
    )

    stream_url = f"{SIMULATOR_URL}/api/telemetry/stream/{topic_name}"

    while True:
        try:
            print(f"Connecting to telemetry topic: {topic_name}")

            with requests.get(stream_url, stream=True, timeout=30) as response:
                response.raise_for_status()

                for raw_line in response.iter_lines(decode_unicode=True):
                    if not raw_line:
                        continue


                    if raw_line.startswith("data:"):
                        data_str = raw_line[len("data:"):].strip()

                        if not data_str:
                            continue

                        try:
                            payload = json.loads(data_str)
                            event = normalize_telemetry_event(topic_name, payload)
                            publish_event(channel, event)
                        except Exception as e:
                            print(f"Telemetry parse/publish error on {topic_name}: {e}")

        except Exception as e:
            print(f"Telemetry stream error on {topic_name}: {e}")
            time.sleep(3)


def start_telemetry_consumers():
    try:
        topics = get_telemetry_topics()
        print("Telemetry topics:", topics)

        for topic in topics:
            t = threading.Thread(target=consume_single_topic, args=(topic,), daemon=True)
            t.start()

    except Exception as e:
        print("Could not start telemetry consumers:", e)


# ---------------------------------------------------
# main
# ---------------------------------------------------

def main():
    wait_for_simulator()

    rest_connection = wait_for_rabbitmq()
    rest_channel = rest_connection.channel()

    rest_channel.exchange_declare(
        exchange=EXCHANGE_NAME,
        exchange_type="fanout"
    )

    print("Ingestion Service started")

    # avvia i consumer telemetry in thread separati
    start_telemetry_consumers()

    # continua il polling REST nel thread principale
    poll_rest_sensors(rest_channel)


if __name__ == "__main__":
    main()