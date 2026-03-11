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

# CONTAINERS:

---

# CONTAINER_NAME: Mars-Simulator

### DESCRIPTION:
The Mars-Simulator provides the simulated environment of the habitat. It exposes sensors, telemetry streams, and actuators used by the platform for monitoring and automation. The simulator is provided as an external service and is used as the primary data source for the system.

### USER STORIES:

- 6 - As a habitat operator, I want the system to ingest data from REST-based sensors, so that periodically polled devices are included in monitoring.

- 7 - As a habitat operator, I want the system to ingest data from stream-based telemetry topics, so that asynchronous devices are also monitored.

- 19 - As a habitat operator, I want to view the current state of each actuator, so that I know which control devices are active.

- 20 - As a habitat operator, I want to manually toggle an actuator from the dashboard, so that I can override automation when needed.

### PORTS:
8080:8080

### PERSISTENCE EVALUATION
The Mars Simulator does not persist data within the platform architecture. It generates simulated sensor measurements and actuator states at runtime.

### EXTERNAL SERVICES CONNECTIONS
The simulator does not depend on other services in the platform. It is instead consumed by several platform components.

### MICROSERVICES:

#### MICROSERVICE: mars-simulator
- TYPE: external service
- DESCRIPTION: Simulates sensors, telemetry streams, and actuators of the Martian habitat.
- PORTS: 8080

- TECHNOLOGICAL SPECIFICATION:
The simulator is provided as a prebuilt Docker image (`mars-iot-simulator:multiarch_v1`).  
It exposes REST APIs for retrieving sensors, telemetry topics, and actuators, as well as telemetry streams for real-time sensor data.

- SERVICE ARCHITECTURE:
The simulator acts as the external environment of the platform.  
The Ingestion-Service retrieves sensor and telemetry data from the simulator.  
The Backend-API and Rule-Engine interact with the simulator actuator API to control devices.

---

# CONTAINER_NAME: Ingestion-Service

### DESCRIPTION:
The Ingestion-Service is responsible for collecting sensor data from the Mars simulator and converting heterogeneous payloads into a normalized internal event format. The service retrieves sensor data through REST polling and telemetry streams and publishes the resulting events to the message broker.

### USER STORIES:

- 6 - As a habitat operator, I want the system to ingest data from REST-based sensors, so that periodically polled devices are included in monitoring.

- 7 - As a habitat operator, I want the system to ingest data from stream-based telemetry topics, so that asynchronous devices are also monitored.

- 8 - As a habitat operator, I want heterogeneous device payloads to be converted into a unified internal event format, so that the platform can process all data consistently.

- 24 - As a habitat operator, I want the platform services to communicate through a message broker, so that the architecture remains decoupled and event-driven.

- 25 - As a habitat operator, I want the whole platform to start with a single docker compose command, so that the system is easy to deploy and demonstrate.


### PORTS:
No external ports exposed.

### PERSISTENCE EVALUATION
The ingestion service does not persist data. It processes sensor events in real time and forwards them to the message broker.

### EXTERNAL SERVICES CONNECTIONS
The service connects to:
- Mars Simulator REST API for sensor data retrieval
- RabbitMQ message broker for event publishing

### MICROSERVICES:

#### MICROSERVICE: ingestion-service
- TYPE: backend
- DESCRIPTION: Collects sensor data and publishes normalized events.
- PORTS: none

- TECHNOLOGICAL SPECIFICATION:
The microservice is implemented in Python using the following libraries:
    - requests for HTTP communication with the simulator
    - pika for publishing events to RabbitMQ

- SERVICE ARCHITECTURE:
The service periodically polls REST sensors and also subscribes to telemetry streams. All incoming payloads are normalized into a common internal event structure before being published to the RabbitMQ exchange.

---

# CONTAINER_NAME: State-Service

### DESCRIPTION:
The State-Service consumes sensor events from the message broker and maintains the latest state of each sensor in memory. This state is exposed through REST endpoints so that the frontend dashboard can quickly retrieve the most recent values.

### USER STORIES:

- 1 - As a habitat operator, I want to view the latest value of each sensor, so that I can monitor the current status of the habitat.

- 2 - As a habitat operator, I want to see sensor data update in real time on the dashboard, so that I can react quickly to changing conditions.

- 4 - As a habitat operator, I want to view the measurement unit associated with each sensor value, so that I can correctly interpret incoming data.

- 5 - As a habitat operator, I want to see the timestamp of the latest update for each sensor, so that I can verify data freshness.

- 9 - As a habitat operator, I want the platform to keep the latest state of each sensor in memory, so that the dashboard can quickly display current values.

### PORTS:
8001:8001

### PERSISTENCE EVALUATION
The state service does not use persistent storage. Sensor states are stored in memory and are reset if the container restarts.

### EXTERNAL SERVICES CONNECTIONS
The service connects to:
- RabbitMQ to consume sensor events.

### MICROSERVICES:

#### MICROSERVICE: state-service
- TYPE: backend
- DESCRIPTION: Maintains the latest sensor state in memory.
- PORTS: 8001

- TECHNOLOGICAL SPECIFICATION:
The microservice is implemented in Python using:
    - FastAPI for REST endpoints
    - Uvicorn as the application server
    - pika for consuming messages from RabbitMQ

- SERVICE ARCHITECTURE:
A background thread continuously consumes events from RabbitMQ. Each incoming event updates the in-memory state of the corresponding sensor. The REST API exposes endpoints that allow clients to retrieve the latest state.

- ENDPOINTS:

    | HTTP METHOD | URL | Description | User Stories |
    |-------------|-----|-------------|-------------|
    | GET | /health | Service health check | 24 |
    | GET | /state/sensors | Returns latest state of all sensors | 1, 2, 4, 5, 9 |
    | GET | /state/sensors/{source_name} | Returns latest state of a specific sensor | 1, 9 |

---

# CONTAINER_NAME: Rule-Engine

### DESCRIPTION:
The Rule Engine evaluates automation rules against incoming sensor events. When a rule condition is satisfied, the engine sends a command to the corresponding actuator.

### USER STORIES:

- 10 - As a habitat operator, I want to create an automation rule based on a sensor threshold, so that the system can react automatically to dangerous conditions.

- 11 - As a habitat operator, I want to define the sensor, comparison operator, threshold value, and actuator action of a rule, so that I can express simple if-then automations.

- 12 - As a habitat operator, I want automation rules to be evaluated every time a new event arrives, so that reactions happen immediately.

- 13 - As a habitat operator, I want a rule to switch an actuator on when its condition is met, so that the habitat can self-regulate.

- 14 - As a habitat operator, I want a rule to switch an actuator off when its condition is met, so that devices are not kept active unnecessarily.

- 18 - As a habitat operator, I want automation rules to be persisted in a database, so that they survive service restarts.

- 24 - As a habitat operator, I want the platform services to communicate through a message broker, so that the architecture remains decoupled and event-driven.


### PORTS:
No ports exposed.

### PERSISTENCE EVALUATION
The rule engine does not persist runtime state. Automation rules are stored in PostgreSQL.

### EXTERNAL SERVICES CONNECTIONS
The service connects to:
- RabbitMQ for event consumption
- PostgreSQL database for rule retrieval
- Mars Simulator actuator API to trigger actuators

### MICROSERVICES:

#### MICROSERVICE: rule-engine
- TYPE: backend
- DESCRIPTION: Evaluates automation rules and triggers actuators.
- PORTS: none

- TECHNOLOGICAL SPECIFICATION:
The microservice is implemented in Python and uses:
    - pika for RabbitMQ communication
    - psycopg2 for PostgreSQL interaction
    - requests for actuator API calls

- SERVICE ARCHITECTURE:
The service consumes sensor events from RabbitMQ. For each event, it retrieves active rules from the database and evaluates rule conditions against sensor values. If a rule matches, the service sends an actuator command to the simulator.

---

# CONTAINER_NAME: Backend-API

### DESCRIPTION:
The Backend API exposes the main REST interface used by the frontend. It provides endpoints for retrieving sensor data, managing automation rules, and controlling actuators.

### USER STORIES:

- 1 - As a habitat operator, I want to view the latest value of each sensor, so that I can monitor the current status of the habitat.

- 2 - As a habitat operator, I want to see sensor data update in real time on the dashboard, so that I can react quickly to changing conditions.

- 10 - As a habitat operator, I want to create an automation rule based on a sensor threshold, so that the system can react automatically to dangerous conditions.

- 15 - As a habitat operator, I want to view all configured automation rules, so that I can inspect the current automation setup.

- 16 - As a habitat operator, I want to edit an existing automation rule, so that I can refine the system behavior without recreating it from scratch.

- 17 - As a habitat operator, I want to delete an automation rule, so that obsolete or incorrect automations can be removed.

- 19 - As a habitat operator, I want to view the current state of each actuator, so that I know which control devices are active.

- 20 - As a habitat operator, I want to manually toggle an actuator from the dashboard, so that I can override automation when needed.

### PORTS:
8000:8000

### PERSISTENCE EVALUATION
Automation rules are stored in PostgreSQL.

### EXTERNAL SERVICES CONNECTIONS
The service connects to:
- State-Service for sensor state retrieval
- PostgreSQL for rule storage
- Mars Simulator actuator API

### MICROSERVICES:

#### MICROSERVICE: backend-api
- TYPE: backend
- DESCRIPTION: REST API gateway used by the frontend.
- PORTS: 8000

- TECHNOLOGICAL SPECIFICATION:
The microservice is implemented in Python using:
    - FastAPI for API implementation
    - Uvicorn as the web server
    - requests for service communication
    - psycopg2 for PostgreSQL access
    - Pydantic for request validation

- SERVICE ARCHITECTURE:
The backend exposes endpoints grouped into sensor retrieval, rule management, and actuator control. It communicates with the State-Service to retrieve sensor data and interacts with PostgreSQL to manage automation rules.

- ENDPOINTS:

    | HTTP METHOD | URL | Description | User Stories |
    |-------------|-----|-------------|-------------|
    | GET | /health | Service health check | 24 |
    | GET | /api/sensors/latest | Returns latest sensor values | 1, 2 |
    | GET | /api/rules | Returns automation rules | 15 |
    | POST | /api/rules | Creates a new rule | 10 |
    | PUT | /api/rules/{id} | Updates a rule | 16 |
    | DELETE | /api/rules/{id} | Deletes a rule | 17 |
    | GET | /api/actuators | Returns actuators and their states | 19 |
    | POST | /api/actuators/{actuator} | Changes actuator state | 20 |

- DB STRUCTURE:

    **rules**

        | id | source_name | metric_name | operator | threshold_value | actuator_name | target_state | enabled |

---

# CONTAINER_NAME: Frontend

### DESCRIPTION:
The Frontend provides the graphical interface used by the habitat operator. It allows monitoring sensor values, controlling actuators, viewing alerts, and managing automation rules.

### USER STORIES:

- 1 - As a habitat operator, I want to view the latest value of each sensor, so that I can monitor the current status of the habitat.

- 2 - As a habitat operator, I want to see sensor data update in real time on the dashboard, so that I can react quickly to changing conditions.

- 3 - As a habitat operator, I want to distinguish sensor data by type, so that I can better understand environmental, chemical, power, and thermal measurements.

- 4 - As a habitat operator, I want to view the measurement unit associated with each sensor value, so that I can correctly interpret incoming data.

- 5 - As a habitat operator, I want to see the timestamp of the latest update for each sensor, so that I can verify data freshness.

- 10 - As a habitat operator, I want to create an automation rule based on a sensor threshold, so that the system can react automatically to dangerous conditions.

- 11 - As a habitat operator, I want to define the sensor, comparison operator, threshold value, and actuator action of a rule, so that I can express simple if-then automations.

- 15 - As a habitat operator, I want to view all configured automation rules, so that I can inspect the current automation setup.

- 16 - As a habitat operator, I want to edit an existing automation rule, so that I can refine the system behavior without recreating it from scratch.

- 17 - As a habitat operator, I want to delete an automation rule, so that obsolete or incorrect automations can be removed.

- 19 - As a habitat operator, I want to view the current state of each actuator, so that I know which control devices are active.

- 20 - As a habitat operator, I want to manually toggle an actuator from the dashboard, so that I can override automation when needed.

- 21 - As a habitat operator, I want to be notified on the dashboard when a rule is triggered, so that I can understand why an actuator changed state.

### PORTS:
None (static web application)

### PERSISTENCE EVALUATION
The frontend does not persist data. All state is retrieved from backend services.

### EXTERNAL SERVICES CONNECTIONS
The frontend communicates with the Backend API via HTTP requests.

### MICROSERVICES:

#### MICROSERVICE: frontend
- TYPE: frontend
- DESCRIPTION: User interface for monitoring sensors and managing automations.
- PORTS: none

- TECHNOLOGICAL SPECIFICATION:
The frontend is implemented using:
    - HTML
    - CSS
    - JavaScript
    - SweetAlert2 for popup dialogs

- SERVICE ARCHITECTURE:
The frontend is composed of two main pages and a shared navigation bar with a notification system.

- PAGES:

| Name | Description | Related Microservice | User Stories |
|-----|-------------|---------------------|-------------|
| Dashboard | Displays live sensor values, actuator states, allows manual control of actuators, and shows alerts in the notification area when abnormal sensor conditions are detected. | backend-api | 1,2,3,4,5,19,20,21 |
| Automations | Displays automation rules and allows creation, editing, and deletion of rules through a graphical interface. | backend-api | 10,11,15,16,17 |