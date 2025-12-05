# app/mqtt_client.py
import threading
import time
import paho.mqtt.client as mqtt
import os
import json

MQTT_BROKER = os.environ.get("MQTT_BROKER", "localhost")
MQTT_PORT = int(os.environ.get("MQTT_PORT", 1883))
TOPIC_LIGHT_CONTROL = os.environ.get("TOPIC_LIGHT_CONTROL", "traffic/light/control")
# optional: receive topics if needed
client = mqtt.Client()

def start_mqtt():
    try:
        client.connect(MQTT_BROKER, MQTT_PORT, 60)
        client.loop_start()
        print("MQTT connected to", MQTT_BROKER)
    except Exception as e:
        print("MQTT connect error:", e)

def start_in_thread():
    t = threading.Thread(target=start_mqtt, daemon=True)
    t.start()

def publish_light(intersection: str, red: int, yellow: int, green: int):
    payload = {"intersection": intersection, "red": red, "yellow": yellow, "green": green}
    try:
        client.publish(TOPIC_LIGHT_CONTROL, json.dumps(payload))
        print("Published light control:", payload)
    except Exception as e:
        print("MQTT publish error:", e)
