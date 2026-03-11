# SYSTEM DESCRIPTION:

Mars Habitat Automation Platform is a distributed system for monitoring a simulated Martian habitat. The platform collects data from different types of sensors, including REST-polled devices and telemetry streams. Incoming data is converted into a common internal event format before being published to the message broker. The automation engine evaluates predefined rules on incoming events and updates actuators when needed. A dashboard allows operators to monitor the habitat conditions, inspect the current state of actuators, manually control them, and manage automation rules. The system is organized into multiple backend services that communicate through a message broker. Automation rules are stored in a database, while the latest state of each sensor is kept in memory for fast access.

# USER STORIES:

1. As a habitat operator, I want to view the latest value of each sensor, so that I can monitor the current status of the habitat.

2. As a habitat operator, I want to see sensor data update in real time on the dashboard, so that I can react quickly to changing conditions.

3. As a habitat operator, I want to distinguish sensor data by type, so that I can better understand environmental, chemical, power, and thermal measurements.

4. As a habitat operator, I want to view the measurement unit associated with each sensor value, so that I can correctly interpret incoming data.

5. As a habitat operator, I want to see the timestamp of the latest update for each sensor, so that I can verify data freshness.

6. As a habitat operator, I want the system to ingest data from REST-based sensors, so that periodically polled devices are included in monitoring.

7. As a habitat operator, I want the system to ingest data from stream-based telemetry topics, so that asynchronous devices are also monitored.

8. As a habitat operator, I want heterogeneous device payloads to be converted into a unified internal event format, so that the platform can process all data consistently.

9. As a habitat operator, I want the platform to keep the latest state of each sensor in memory, so that the dashboard can quickly display current values.

10. As a habitat operator, I want to create an automation rule based on a sensor threshold, so that the system can react automatically to dangerous conditions.

11. As a habitat operator, I want to define the sensor, comparison operator, threshold value, and actuator action of a rule, so that I can express simple if-then automations.

12. As a habitat operator, I want automation rules to be evaluated every time a new event arrives, so that reactions happen immediately.

13. As a habitat operator, I want a rule to switch an actuator on when its condition is met, so that the habitat can self-regulate.

14. As a habitat operator, I want a rule to switch an actuator off when its condition is met, so that devices are not kept active unnecessarily.

15. As a habitat operator, I want to view all configured automation rules, so that I can inspect the current automation setup.

16. As a habitat operator, I want to edit an existing automation rule, so that I can refine the system behavior without recreating it from scratch.

17. As a habitat operator, I want to delete an automation rule, so that obsolete or incorrect automations can be removed.

18. As a habitat operator, I want automation rules to be persisted in a database, so that they survive service restarts.

19. As a habitat operator, I want to view the current state of each actuator, so that I know which control devices are active.

20. As a habitat operator, I want to manually toggle an actuator from the dashboard, so that I can override automation when needed.

21. As a habitat operator, I want to be notified on the dashboard when a rule is triggered, so that I can understand why an actuator changed state.

22. As a habitat operator, I want to inspect the list of available sensors discovered from the simulator, so that I know which data sources are connected.

23. As a habitat operator, I want to inspect the list of available telemetry topics, so that I know which streams are being consumed.

24. As a habitat operator, I want the platform services to communicate through a message broker, so that the architecture remains decoupled and event-driven.

25. As a habitat operator, I want the whole platform to start with a single docker compose command, so that the system is easy to deploy and demonstrate.


# STANDARD EVENT SCHEMA:

To handle the heterogeneity of the incoming data from the Mars IoT Simulator (REST polling and Telemetry streams), the Ingestion Service normalizes all payloads into a single, unified JSON format before publishing them to the message broker. 

This standard internal event format ensures that the Rule Engine and State Service can process any data without knowing its original source schema.

## Normalized Event Structure
```json
{
  "source_name": "string",
  "timestamp": "ISO-8601 datetime",
  "source_type": "rest | telemetry",
  "metrics": [
    {
      "name": "string",
      "value": "number",
      "unit": "string"
    }
  ],
  "status": "ok | warning | unknown"
}
```
Example of a normalized REST sensor (greenhouse_temperature):
```json
{
  "source_name": "greenhouse_temperature",
  "timestamp": "2036-03-05T14:30:00Z",
  "source_type": "rest",
  "metrics": [
    {
      "name": "temperature",
      "value": 24.5,
      "unit": "°C"
    }
  ],
  "status": "ok"
}
```
Example of a normalized Stream payload (air_quality_pm25):
```json
{
  "source_name": "air_quality_pm25",
  "timestamp": "2036-03-05T14:30:05Z",
  "source_type": "rest",
  "metrics": [
    {
      "name": "pm1",
      "value": 5.2,
      "unit": "ug/m3"
    },
    {
      "name": "pm25",
      "value": 12.0,
      "unit": "ug/m3"
    },
    {
      "name": "pm10",
      "value": 15.3,
      "unit": "ug/m3"
    }
  ],
  "status": "warning"
}
```
Example of a normalized telemetry event (power_bus):
```json
{
  "source_name": "mars/telemetry/power_bus",
  "timestamp": "2036-03-05T14:30:10Z",
  "source_type": "telemetry",
  "metrics": [
    {
      "name": "power_kw",
      "value": 5.4,
      "unit": "kW"
    },
    {
      "name": "voltage_v",
      "value": 230,
      "unit": "V"
    },
    {
      "name": "current_a",
      "value": 23.5,
      "unit": "A"
    }
  ],
  "status": "unknown"
}
```
# RULE MODEL

The platform supports simple event-triggered automation rules.  
Each rule is evaluated whenever a new normalized event is received from the message broker. If the condition is satisfied, the corresponding actuator command is sent to the simulator.

Each rule targets a specific source and one metric contained in the normalized event.

## Rule Structure

```json
{
  "rule_id": "string",
  "source_name": "string",
  "metric": "string",
  "operator": "< | <= | = | > | >=",
  "threshold": "number",
  "actuator_name": "string",
  "target_state": "ON | OFF"
}
```
Example Rule: Temperature-Based Cooling Activation
```json
{
  "source_name": "greenhouse_temperature",
  "metric": "temperature",
  "operator": ">",
  "threshold": 28,
  "actuator_name": "cooling_fan",
  "target_state": "ON"
}
```
Example Rule: Low Humidity Humidifier Activation
```json
{
  "source_name": "entrance_humidity",
  "metric": "humidity",
  "operator": "<",
  "threshold": 30,
  "actuator_name": "entrance_humidifier",
  "target_state": "ON"
}
```
Example Rule: High CO₂ Ventilation Activation
```json
{
  "source_name": "co2_hall",
  "metric": "co2",
  "operator": ">",
  "threshold": 900,
  "actuator_name": "hall_ventilation",
  "target_state": "ON"
}
```