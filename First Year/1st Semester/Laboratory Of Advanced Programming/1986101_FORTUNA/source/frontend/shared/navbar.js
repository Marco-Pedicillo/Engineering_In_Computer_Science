function renderNavbar(activePage) {
  const navbarContainer = document.getElementById("shared-navbar");

  if (!navbarContainer) return;

  navbarContainer.innerHTML = `
    <header class="topbar">
      <div class="brand">MARS OS</div>

      <nav class="nav-links">
        <a href="../dashboard/index.html" class="${activePage === "dashboard" ? "active" : ""}">Dashboard</a>
        <a href="../automations/index.html" class="${activePage === "automations" ? "active" : ""}">Automations</a>
      </nav>

      <div class="topbar-right">
        <span id="alert-badge" class="alert-symbol hidden" style="display: none; color: #e74c3c; font-weight: bold; margin-right: 10px;">!</span>

        <button id="notification-btn" class="notification-btn" type="button" aria-label="Open notifications">
          <span class="bell">🔔</span>
        </button>
      </div>
    </header>

    <div id="notification-popup" class="notification-popup hidden">
      <div class="notification-popup-header">Notifications</div>
      
      <div id="notifications-container">
        <div class="notification-item">No new alerts.</div>
      </div>
    </div>
  `;

  const notificationBtn = document.getElementById("notification-btn");
  const notificationPopup = document.getElementById("notification-popup");

  if (!notificationBtn || !notificationPopup) return;

  notificationBtn.addEventListener("click", (event) => {
    event.stopPropagation();
    notificationPopup.classList.toggle("hidden");
  });

  document.addEventListener("click", (event) => {
    const clickedInsidePopup = notificationPopup.contains(event.target);
    const clickedButton = notificationBtn.contains(event.target);

    if (!clickedInsidePopup && !clickedButton) {
      notificationPopup.classList.add("hidden");
    }
  });
}

// Funzione globale per gestire allarmi ed eventi attuatori
window.updateNotifications = function(alerts = [], actuatorLogs = []) {
    const container = document.getElementById("notifications-container");
    const badge = document.getElementById("alert-badge");
    
    if (!container) return;

    if (alerts.length === 0 && actuatorLogs.length === 0) {
        container.innerHTML = '<div class="notification-item">No new alerts.</div>';
        if(badge) badge.style.display = 'none';
    } else {
        let htmlContent = "";

        alerts.forEach(alert => {
            htmlContent += `
            <div class="notification-item" style="color: #e74c3c; border-left: 3px solid #e74c3c;">
                <strong>⚠️ WARNING:</strong> ${alert}
            </div>`;
        });

        actuatorLogs.forEach(log => {
            htmlContent += `
            <div class="notification-item" style="color: #3498db; border-left: 3px solid #3498db;">
                <strong>🔄 SYSTEM:</strong> ${log}
            </div>`;
        });

        container.innerHTML = htmlContent;
        
        
        if(badge) {
            badge.style.display = 'inline-block';
            badge.style.color = alerts.length > 0 ? '#e74c3c' : '#3498db';
            badge.textContent = alerts.length > 0 ? '!' : 'i';
        }
    }
};