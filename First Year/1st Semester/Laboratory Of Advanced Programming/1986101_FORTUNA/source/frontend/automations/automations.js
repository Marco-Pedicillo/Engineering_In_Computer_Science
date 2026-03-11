renderNavbar("automations");

const API_URL = "http://localhost:8000/api";
let rules = [];

async function loadRules() {
  try {
    const response = await fetch(`${API_URL}/rules`);
    if (response.ok) {
      rules = await response.json();
      renderRules();
    }
  } catch (error) {
    console.error("Errore nel caricamento delle regole:", error);
  }
}

const sensors = [
  { value: "greenhouse_temperature", label: "Greenhouse Temperature" },
  { value: "entrance_humidity", label: "Entrance Humidity" },
  { value: "co2_hall", label: "CO2 Hall" },
  { value: "corridor_pressure", label: "Corridor Pressure" },
  { value: "air_quality_pm25", label: "Air Quality PM2.5" },
  { value: "air_quality_voc", label: "Air Quality VOC" }
];

const allActuators = [
  { value: "cooling_fan", label: "Cooling Fan" },
  { value: "entrance_humidifier", label: "Entrance Humidifier" },
  { value: "hall_ventilation", label: "Hall Ventilation" },
  { value: "habitat_heater", label: "Habitat Heater" }
];

function renderRules() {
  const tableBody = document.getElementById("rules-table-body");
  tableBody.innerHTML = "";

  rules.forEach((rule) => {
    const row = document.createElement("tr");

    row.innerHTML = `
      <td>${rule.id}</td>
      <td>IF ${prettifySourceName(rule.source_name)} ${rule.operator} ${rule.threshold_value}</td>
      <td>Set ${prettifyActuatorName(rule.actuator_name)} to ${rule.target_state}</td>
      <td>
        <div class="manage-actions">
          <button class="manage-btn edit-btn">Edit</button>
          <button class="manage-btn delete-btn">Delete</button>
        </div>
      </td>
    `;

    tableBody.appendChild(row);
  });
}

function buildOptions(list) {
  return list
    .map(item => `<option value="${item.value}">${item.label}</option>`)
    .join("");
}

function prettifySourceName(sourceName) {
  const found = sensors.find(s => s.value === sourceName);
  return found ? found.label : sourceName;
}

function prettifyActuatorName(actuatorName) {
  const found = allActuators.find(a => a.value === actuatorName);
  return found ? found.label : actuatorName;
}

function openRuleModal(mode = "create", rule = null) {
  const isEdit = mode === "edit";

  Swal.fire({
    didOpen: () => { populateActuatorSelect(isEdit ? rule.actuator_name : ""); },
    title: isEdit ? "EDIT AUTOMATION RULE" : "CREATE NEW AUTOMATION",
    html: `
      <div class="rule-form">
        <label for="swal-sensor">Sensor:</label>
        <select id="swal-sensor" class="swal2-input swal-custom-select">
          <option value="" disabled ${!isEdit ? "selected" : ""}>Choose a sensor</option>
          ${sensors.map(sensor => `
            <option value="${sensor.value}" ${isEdit && rule.source_name === sensor.value ? "selected" : ""}>
              ${sensor.label}
            </option>
          `).join("")}
        </select>

        <label for="swal-operator">Operator:</label>
        <select id="swal-operator" class="swal2-input swal-custom-select">
          <option value="" disabled ${!isEdit ? "selected" : ""}>Choose an operator</option>
          <option value="<" ${isEdit && rule.operator === "<" ? "selected" : ""}><</option>
          <option value="<=" ${isEdit && rule.operator === "<=" ? "selected" : ""}><=</option>
          <option value="=" ${isEdit && rule.operator === "=" ? "selected" : ""}>=</option>
          <option value=">" ${isEdit && rule.operator === ">" ? "selected" : ""}>></option>
          <option value=">=" ${isEdit && rule.operator === ">=" ? "selected" : ""}>>=</option>
        </select>

        <label for="swal-threshold">Threshold Value:</label>
        <input 
          id="swal-threshold" 
          class="swal2-input swal-custom-input" 
          placeholder="Set a threshold value"
          value="${isEdit ? rule.threshold_value : ""}"
        />

        <label for="swal-actuator">Actuator:</label>
        <select id="swal-actuator" class="swal2-input swal-custom-select">
            <option value="" selected disabled>Choose an actuator</option>
        </select>

        <label>Action:</label>
        <div class="swal-radio-group">
          <label>
            <input type="radio" name="swal-action" value="ON" ${!isEdit || rule.target_state === "ON" ? "checked" : ""}>
            ON
          </label>
          <label>
            <input type="radio" name="swal-action" value="OFF" ${isEdit && rule.target_state === "OFF" ? "checked" : ""}>
            OFF
          </label>
        </div>
      </div>
    `,
    showCancelButton: true,
    confirmButtonText: "Save",
    cancelButtonText: "Cancel",
    customClass: {
      popup: "rule-popup",
      confirmButton: "swal-save-btn",
      cancelButton: "swal-cancel-btn"
    },
    buttonsStyling: false,
    focusConfirm: false,
    preConfirm: () => {
      const sensor = document.getElementById("swal-sensor").value;
      const operator = document.getElementById("swal-operator").value;
      const threshold = document.getElementById("swal-threshold").value.trim();
      const actuator = document.getElementById("swal-actuator").value;
      const action = document.querySelector('input[name="swal-action"]:checked')?.value;

      if (!sensor || !operator || !threshold || !actuator || !action) {
        Swal.showValidationMessage("Please complete all fields.");
        return false;
      }

      if (isNaN(Number(threshold))) {
        Swal.showValidationMessage("Threshold value must be numeric.");
        return false;
      }

      return {
        source_name: sensor,
        operator,
        threshold,
        actuator_name: actuator,
        target_state: action
      };
    }
  }).then(async (result) => {
    if (!result.isConfirmed) return;

    try {
        const payload = {
            source_name: result.value.source_name,
            operator: result.value.operator,
            threshold_value: parseFloat(result.value.threshold),
            actuator_name: result.value.actuator_name,
            target_state: result.value.target_state
        };

        const url = isEdit ? `${API_URL}/rules/${rule.id}` : `${API_URL}/rules`;
        const method = isEdit ? 'PUT' : 'POST';

        const res = await fetch(url, {
            method: method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (res.ok) {
            await loadRules(); 
            Swal.fire({
              icon: "success",
              title: isEdit ? "Rule updated" : "Rule created",
              text: isEdit ? "The automation rule has been updated." : "The new automation rule has been added.",
              timer: 1400,
              showConfirmButton: false
            });
        } else {
            Swal.fire("Errore", "Impossibile salvare la regola", "error");
        }
    } catch (error) {
        console.error("Errore salvataggio:", error);
    }
  });
}

function populateActuatorSelect(selectedActuator = "") {
  const actuatorSelect = document.getElementById("swal-actuator");
  if (!actuatorSelect) return;

  actuatorSelect.innerHTML = `
    <option value="" disabled ${selectedActuator ? "" : "selected"}>
      Choose an actuator
    </option>
    ${allActuators
      .map(actuator => `
        <option value="${actuator.value}" ${selectedActuator === actuator.value ? "selected" : ""}>
          ${actuator.label}
        </option>
      `)
      .join("")}
  `;
}

document.addEventListener("click", function (e) {
  if (e.target.classList.contains("delete-btn")) {
    const row = e.target.closest("tr");
    const rowId = Number(row.children[0].textContent);

    Swal.fire({
      title: "Are you sure?",
      text: "This rule will be deleted.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Yes",
      cancelButtonText: "No",
      confirmButtonColor: "#4db264",
      cancelButtonColor: "#d33"
    }).then(async (result) => {
      if (!result.isConfirmed) return;

      try {
          const res = await fetch(`${API_URL}/rules/${rowId}`, { method: 'DELETE' });
          if (res.ok) {
              await loadRules(); // Ricarica le regole aggiornate
              Swal.fire({
                title: "Deleted!",
                text: "The rule has been removed.",
                icon: "success",
                timer: 1200,
                showConfirmButton: false
              });
          }
      } catch (error) {
          console.error("Errore durante l'eliminazione:", error);
      }
    });
  }

  if (e.target.classList.contains("edit-btn")) {
    const row = e.target.closest("tr");
    const rowId = Number(row.children[0].textContent);
    const ruleToEdit = rules.find(rule => rule.id === rowId);

    if (ruleToEdit) {
      openRuleModal("edit", ruleToEdit);
    }
  }
});

document.getElementById("add-rule-btn").addEventListener("click", () => {
  openRuleModal("create");
});

loadRules();

// ==========================================
// MOTORE NOTIFICHE IN BACKGROUND (POLLING CONDIVISO E TTL 5 SEC)
// ==========================================
let previousActuators = {}; 

async function pollNotifications() {
  const now = Date.now();
  try {
    // 1. Controllo Sensori (per allarmi)
    const resSensors = await fetch(`${API_URL}/sensors/latest`);
    let activeAlerts = [];
    
    if (resSensors.ok) {
        const rawSensors = await resSensors.json();
        Object.values(rawSensors).forEach(sensor => {
            if (sensor.status === 'warning' || sensor.status === 'critical') {
                let cleanName = sensor.source_name.replace("mars/telemetry/", "");
                const formattedName = cleanName.split('_').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
                const metric = sensor.metrics && sensor.metrics.length > 0 ? sensor.metrics[0] : { value: 'N/A', unit: '' };
                const unitDisplay = metric.unit && metric.unit !== null ? metric.unit : '';
                
                activeAlerts.push(`High values detected on ${formattedName} (${metric.value} ${unitDisplay})`);
            }
        });
    }

    // 2. Controllo Attuatori (per cambi di stato)
    const resActuators = await fetch(`${API_URL}/actuators`);
    if (resActuators.ok) {
        const data = await resActuators.json();
        const actuatorsMap = data.actuators;

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

        const oldLength = sharedLogs.length;
        sharedLogs = sharedLogs.filter(log => (now - log.timestamp) <= 5000);

        // aggiornamento memoria
        if (logsChanged || sharedLogs.length !== oldLength) {
            localStorage.setItem("mars_logs", JSON.stringify(sharedLogs));
        }

        // 3. Invia i dati alla sezione notifiche
        if (typeof window.updateNotifications === "function") {
            window.updateNotifications(activeAlerts, sharedLogs.map(l => l.text));
        }
    }

  } catch (error) {
      console.error("Errore nel polling delle notifiche:", error);
  }
}

// Avvia subito il controllo e ripetilo ogni 5 secondi
pollNotifications();
setInterval(pollNotifications, 5000);