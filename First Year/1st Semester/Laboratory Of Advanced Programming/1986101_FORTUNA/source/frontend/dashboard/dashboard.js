renderNavbar("dashboard");

const API_URL = "http://localhost:8000/api";
let sensors = [];
let previousActuators = {}; 

async function renderSensors() {
  const container = document.getElementById("sensor-list");
  container.innerHTML = ""; 

  try {
    const response = await fetch(`${API_URL}/sensors/latest`);
    if (response.ok) {
        const rawData = await response.json();
        sensors = Object.values(rawData);
    }
  } catch (error) {
    console.error("Errore nel recupero dei sensori:", error);
  }

  let activeAlerts = [];
  sensors.forEach((sensor) => {
    const card = document.createElement("div");
    card.className = "sensor-card";

    let cleanName = sensor.source_name.replace("mars/telemetry/", "");
    const formattedName = cleanName.split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');

    const metric = sensor.metrics && sensor.metrics.length > 0 ? sensor.metrics[0] : { value: 'N/A', unit: '' };
    const unitDisplay = metric.unit && metric.unit !== null ? metric.unit : '';
    const statusColor = sensor.status === 'warning' ? '#f39c12' : (sensor.status === 'ok' ? '#4db264' : '#aaa');

    if (sensor.status === 'warning' || sensor.status === 'critical') {
        activeAlerts.push(`High values detected on ${formattedName} (${metric.value} ${unitDisplay})`);
    }

    card.innerHTML = `
      <div class="sensor-title">${formattedName}: <strong>${metric.value} ${unitDisplay}</strong></div>
      <div class="sensor-update" style="color: ${statusColor}">Status: ${sensor.status.toUpperCase()}</div>
    `;

    container.appendChild(card);
  });

  const minCards = 8;
  for (let i = sensors.length; i < minCards; i++) {
    const emptyCard = document.createElement("div");
    emptyCard.className = "sensor-placeholder";
    container.appendChild(emptyCard);
  }

  // LETTURA, FILTRAGGIO E PULIZIA DEI LOG A 5 SECONDI
  const now = Date.now();
  let sharedLogs = JSON.parse(localStorage.getItem("mars_logs")) || [];
  
  sharedLogs = sharedLogs.filter(log => (now - log.timestamp) <= 5000);
  localStorage.setItem("mars_logs", JSON.stringify(sharedLogs));

  if (typeof window.updateNotifications === "function") {
      window.updateNotifications(activeAlerts, sharedLogs.map(l => l.text));
  }
}

async function renderActuators() {
  const container = document.getElementById("actuator-list");

  try {
    const response = await fetch(`${API_URL}/actuators`);
    if (response.ok) {
        const data = await response.json();
        const actuatorsMap = data.actuators; 
        
        const now = Date.now();
        let sharedLogs = JSON.parse(localStorage.getItem("mars_logs")) || [];
        let logsChanged = false;

        Object.entries(actuatorsMap).forEach(([key, state]) => {
            if (previousActuators[key] !== undefined && previousActuators[key] !== state) {
                const formattedName = key.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
                
                sharedLogs.unshift({ text: `${formattedName} switched to ${state}`, timestamp: now });
                logsChanged = true;
            }
            previousActuators[key] = state;
        });

        if (logsChanged) {
            sharedLogs = sharedLogs.filter(log => (now - log.timestamp) <= 5000);
            localStorage.setItem("mars_logs", JSON.stringify(sharedLogs));
        }

        container.innerHTML = ""; 

        Object.entries(actuatorsMap).forEach(([key, state]) => {
            const card = document.createElement("div");
            card.className = "actuator-card";

            const formattedName = key.split('_')
                .map(word => word.charAt(0).toUpperCase() + word.slice(1))
                .join(' ');

            card.innerHTML = `
                <div class="actuator-name">${formattedName}</div>
                <div class="actuator-actions">
                    <button class="actuator-btn on ${state === 'ON' ? 'active' : ''}" onclick="toggleActuator('${key}', 'ON')">ON</button>
                    <button class="actuator-btn off ${state === 'OFF' ? 'active' : ''}" onclick="toggleActuator('${key}', 'OFF')">OFF</button>
                </div>
            `;
            container.appendChild(card);
        });
    }
  } catch (error) {
    console.error("Errore nel recupero degli attuatori:", error);
  }
}

async function toggleActuator(actuatorName, newState) {
    try {
        await fetch(`${API_URL}/actuators/${actuatorName}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ state: newState })
        });
        renderActuators(); 
        renderSensors(); 
    } catch (error) {
        console.error("Errore durante il cambio di stato:", error);
    }
}

renderSensors();
renderActuators();
setInterval(() => {
    renderSensors();
    renderActuators();
}, 5000);