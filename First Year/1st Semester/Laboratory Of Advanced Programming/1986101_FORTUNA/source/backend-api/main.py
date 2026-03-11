from typing import Optional

import psycopg2
import requests
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

STATE_SERVICE_URL = "http://state-service:8001"
DB_HOST = "postgres"
DB_NAME = "mars_rules"
DB_USER = "postgres"
DB_PASSWORD = "postgres"

app = FastAPI(title="Backend API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------------
# Database helpers
# -----------------------------------

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )


def ensure_rules_table():
    conn = get_db_connection()
    try:
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
    finally:
        conn.close()


# -----------------------------------
# Pydantic models
# -----------------------------------

class RuleCreate(BaseModel):
    source_name: str
    metric_name: str = "value"
    operator: str
    threshold_value: float
    actuator_name: str
    target_state: str
    enabled: bool = True

class ActuatorState(BaseModel):
    state: str
# -----------------------------------
# Startup
# -----------------------------------

@app.on_event("startup")
def startup_event():
    ensure_rules_table()
    print("Backend API started and rules table ensured.")


# -----------------------------------
# Health
# -----------------------------------

@app.get("/health")
def health():
    return {"status": "ok"}


# -----------------------------------
# Sensor endpoints
# -----------------------------------

@app.get("/api/sensors/latest")
def get_latest_sensors():
    try:
        response = requests.get(f"{STATE_SERVICE_URL}/state/sensors", timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"State service unavailable: {str(e)}")

@app.get("/api/sensors/latest/{source_name}")
def get_latest_sensor(source_name: str):
    try:
        response = requests.get(
            f"{STATE_SERVICE_URL}/state/sensors/{source_name}",
            timeout=5
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"State service unavailable: {str(e)}")

# -----------------------------------
# Rules endpoints
# -----------------------------------

@app.get("/api/rules")
def get_rules():
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, source_name, metric_name, operator,
                       threshold_value, actuator_name, target_state, enabled
                FROM rules
                ORDER BY id;
            """)
            rows = cur.fetchall()

        return [
            {
                "id": r[0], 
                "source_name": r[1], 
                "metric_name": r[2],
                "operator": r[3], 
                "threshold_value": r[4],
                "actuator_name": r[5], 
                "target_state": r[6], 
                "enabled": r[7]
            } for r in rows
        ]

    finally:
        conn.close()


# Funzione "Traduttore" per le metriche spaziali
def get_correct_metric_name(source_name: str) -> str:
    mapping = {
        "greenhouse_temperature": "temperature_c",
        "entrance_humidity": "humidity_pct",
        "co2_hall": "co2_ppm",
        "hydroponic_ph": "ph",
        "water_tank_level": "level_pct",
        "corridor_pressure": "pressure_kpa",
        "air_quality_pm25": "pm25_ug_m3",
        "air_quality_voc": "voc_ppb"
    }
    return mapping.get(source_name, "value")

@app.post("/api/rules")
def create_rule(rule: RuleCreate):
    if rule.operator not in [">", "<", ">=", "<=", "="]:
        raise HTTPException(status_code=400, detail="Invalid operator")
    if rule.target_state not in ["ON", "OFF"]:
        raise HTTPException(status_code=400, detail="target_state must be ON or OFF")

    real_metric = get_correct_metric_name(rule.source_name)

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO rules (
                    source_name, metric_name, operator, threshold_value, actuator_name, target_state, enabled
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id;
            """, (
                rule.source_name, real_metric, rule.operator, 
                rule.threshold_value, rule.actuator_name, rule.target_state, rule.enabled
            ))
            new_id = cur.fetchone()[0]
            conn.commit()
        return {"message": "Rule created successfully", "id": new_id}
    finally:
        conn.close()


@app.put("/api/rules/{rule_id}")
def update_rule(rule_id: int, rule: RuleCreate):
    if rule.operator not in [">", "<", ">=", "<=", "="]:
        raise HTTPException(status_code=400, detail="Invalid operator")
    if rule.target_state not in ["ON", "OFF"]:
        raise HTTPException(status_code=400, detail="target_state must be ON or OFF")


    real_metric = get_correct_metric_name(rule.source_name)

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE rules 
                SET source_name = %s, metric_name = %s, operator = %s, 
                    threshold_value = %s, actuator_name = %s, target_state = %s
                WHERE id = %s RETURNING id;
            """, (
                rule.source_name, real_metric, rule.operator, 
                rule.threshold_value, rule.actuator_name, rule.target_state, rule_id
            ))
            updated = cur.fetchone()
            conn.commit()

        if updated is None:
            raise HTTPException(status_code=404, detail="Rule not found")
        return {"message": "Rule updated successfully", "id": rule_id}
    finally:
        conn.close()

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE rules 
                SET source_name = %s, metric_name = %s, operator = %s, 
                    threshold_value = %s, actuator_name = %s, target_state = %s
                WHERE id = %s RETURNING id;
            """, (
                rule.source_name, rule.metric_name, rule.operator, 
                rule.threshold_value, rule.actuator_name, rule.target_state, rule_id
            ))
            updated = cur.fetchone()
            conn.commit()

        if updated is None:
            raise HTTPException(status_code=404, detail="Rule not found")
        
        return {"message": "Rule updated successfully", "id": rule_id}
    finally:
        conn.close()


@app.delete("/api/rules/{rule_id}")
def delete_rule(rule_id: int):
    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM rules WHERE id = %s RETURNING id;", (rule_id,))
            deleted = cur.fetchone()
            conn.commit()

        if deleted is None:
            raise HTTPException(status_code=404, detail="Rule not found")

        return {"message": "Rule deleted successfully", "id": rule_id}

    finally:
        conn.close()

# -----------------------------------
# Actuator endpoints (Proxy al Simulatore)
# -----------------------------------
SIMULATOR_URL = "http://mars-simulator:8080"

@app.get("/api/actuators")
def get_actuators():
    try:
        response = requests.get(f"{SIMULATOR_URL}/api/actuators", timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Simulator unavailable: {str(e)}")

@app.post("/api/actuators/{actuator_name}")
def set_actuator(actuator_name: str, command: ActuatorState):
    if command.state not in ["ON", "OFF"]:
        raise HTTPException(status_code=400, detail="State must be ON or OFF")
    try:
        response = requests.post(
            f"{SIMULATOR_URL}/api/actuators/{actuator_name}",
            json={"state": command.state},
            timeout=5
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Simulator unavailable: {str(e)}")

# -----------------------------------
# Run server
# -----------------------------------

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)