// State Global
let ws = null;
let isConnected = false;
let isHttpMode = false;
let sensitivity = 1.4;
let isDragging = false;
let dragTimer = null;

// Trackpad tracking state
let touchStartX = 0;
let touchStartY = 0;
let touchStartTime = 0;
let lastTouchX = 0;
let lastTouchY = 0;
let touchCount = 0;
let hasMovedSignificant = false;

// DOM Elements
const statusDot = document.getElementById("statusDot");
const statusText = document.getElementById("statusText");
const trackpad = document.getElementById("trackpad");
const sideScroll = document.getElementById("sideScroll");
const btnLeftClick = document.getElementById("btnLeftClick");
const btnRightClick = document.getElementById("btnRightClick");
const sensitivitySlider = document.getElementById("sensitivitySlider");
const sensVal = document.getElementById("sensVal");
const keyboardInput = document.getElementById("keyboardInput");
const btnSendText = document.getElementById("btnSendText");
const screenWrapper = document.getElementById("screenWrapper");
const screenImg = document.getElementById("screenImg");
const btnToggleStream = document.getElementById("btnToggleStream");
const pinModal = document.getElementById("pinModal");
const inputPin = document.getElementById("inputPin");
const btnSubmitPin = document.getElementById("btnSubmitPin");
const pinError = document.getElementById("pinError");
const btnFullscreen = document.getElementById("btnFullscreen");

function vibrate(ms = 12) {
  if (navigator.vibrate) {
    try { navigator.vibrate(ms); } catch (e) {}
  }
}

// ================= DUAL ENGINE: WEBSOCKET & HTTP FALLBACK =================
function connectWebSocket() {
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  const wsUrl = `${protocol}//${window.location.host}/ws`;

  statusText.textContent = "Menghubungkan...";
  statusDot.classList.remove("connected");

  try {
    ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      isConnected = true;
      isHttpMode = false;
      statusText.textContent = "Terhubung (WebSocket)";
      statusDot.classList.add("connected");
      vibrate(25);
      checkServerPinRequirement();
    };

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.type === "auth_result") {
          if (msg.status === "ok") {
            pinModal.classList.remove("show");
            vibrate(30);
          } else {
            pinError.textContent = msg.message || "PIN Salah!";
            pinError.style.display = "block";
            vibrate([40, 50, 40]);
          }
        } else if (msg.type === "cmd_result") {
          appendTerminalOutput(msg.command, msg.output, msg.success);
        }
      } catch (e) {}
    };

    ws.onclose = () => {
      if (!isHttpMode) {
        // Coba mode HTTP jika WebSocket gagal
        tryHttpFallback();
      }
    };

    ws.onerror = () => {
      tryHttpFallback();
    };
  } catch (e) {
    tryHttpFallback();
  }
}

async function tryHttpFallback() {
  try {
    const res = await fetch("/api/info");
    if (res.ok) {
      isHttpMode = true;
      isConnected = true;
      statusText.textContent = "Terhubung (HTTP)";
      statusDot.classList.add("connected");
      const data = await res.json();
      if (data.pin_required) pinModal.classList.add("show");
      return;
    }
  } catch (e) {}

  isConnected = false;
  statusText.textContent = "Terputus. Mencoba...";
  statusDot.classList.remove("connected");
  setTimeout(connectWebSocket, 2500);
}

function sendCommand(obj) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(obj));
  } else {
    // Kirim via HTTP POST jika dalam mode fallback
    fetch("/api/command", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(obj),
    })
      .then((res) => res.json())
      .then((data) => {
        if (obj.type === "cmd_exec" && data.output !== undefined) {
          appendTerminalOutput(obj.command, data.output, data.success);
        }
      })
      .catch(() => {});
  }
}

async function checkServerPinRequirement() {
  try {
    const res = await fetch("/api/info");
    const data = await res.json();
    if (data.pin_required) {
      pinModal.classList.add("show");
    }
  } catch (e) {}
}

btnSubmitPin.addEventListener("click", () => {
  const pin = inputPin.value.trim();
  if (pin) {
    sendCommand({ type: "auth", pin: pin });
  }
});

// ================= TAB NAVIGATION =================
const navTabs = document.querySelectorAll(".nav-tab");
const views = document.querySelectorAll(".view");

navTabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    vibrate(10);
    navTabs.forEach((t) => t.classList.remove("active"));
    views.forEach((v) => v.classList.remove("active"));

    tab.classList.add("active");
    const targetId = tab.getAttribute("data-target");
    const targetView = document.getElementById(targetId);
    if (targetView) targetView.classList.add("active");

    if (targetId !== "viewScreen" && streamActive) {
      screenImg.src = "";
    } else if (targetId === "viewScreen" && streamActive) {
      screenImg.src = "/stream.mjpg";
    }
  });
});

// ================= TRACKPAD GESTURES =================
sensitivitySlider.addEventListener("input", (e) => {
  sensitivity = parseFloat(e.target.value);
  sensVal.textContent = `${sensitivity.toFixed(1)}x`;
});

trackpad.addEventListener("touchstart", (e) => {
  e.preventDefault();
  touchCount = e.touches.length;
  hasMovedSignificant = false;

  if (touchCount === 1) {
    const t = e.touches[0];
    touchStartX = t.clientX;
    touchStartY = t.clientY;
    lastTouchX = t.clientX;
    lastTouchY = t.clientY;
    touchStartTime = Date.now();

    clearTimeout(dragTimer);
    dragTimer = setTimeout(() => {
      if (!hasMovedSignificant) {
        isDragging = true;
        vibrate(40);
        sendCommand({ type: "mouse_down", button: "left" });
      }
    }, 380);
  } else if (touchCount === 2) {
    clearTimeout(dragTimer);
    lastTouchY = (e.touches[0].clientY + e.touches[1].clientY) / 2;
  }
}, { passive: false });

trackpad.addEventListener("touchmove", (e) => {
  e.preventDefault();

  if (e.touches.length === 1) {
    const t = e.touches[0];
    const dx = t.clientX - lastTouchX;
    const dy = t.clientY - lastTouchY;

    const totalDist = Math.hypot(t.clientX - touchStartX, t.clientY - touchStartY);
    if (totalDist > 8) {
      hasMovedSignificant = true;
      clearTimeout(dragTimer);
    }

    if (Math.abs(dx) > 0 || Math.abs(dy) > 0) {
      sendCommand({
        type: "move",
        dx: dx,
        dy: dy,
        sensitivity: sensitivity,
      });
      lastTouchX = t.clientX;
      lastTouchY = t.clientY;
    }
  } else if (e.touches.length === 2) {
    const currentMidY = (e.touches[0].clientY + e.touches[1].clientY) / 2;
    const dy = currentMidY - lastTouchY;
    if (Math.abs(dy) > 1.5) {
      sendCommand({ type: "scroll", dy: dy * 0.08, dx: 0 });
      lastTouchY = currentMidY;
    }
  }
}, { passive: false });

trackpad.addEventListener("touchend", (e) => {
  e.preventDefault();
  clearTimeout(dragTimer);

  if (isDragging) {
    isDragging = false;
    sendCommand({ type: "mouse_up", button: "left" });
    vibrate(15);
    return;
  }

  const duration = Date.now() - touchStartTime;

  if (!hasMovedSignificant && duration < 280) {
    if (touchCount === 1) {
      vibrate(15);
      sendCommand({ type: "click", button: "left" });
    } else if (touchCount === 2) {
      vibrate(25);
      sendCommand({ type: "click", button: "right" });
    }
  }
}, { passive: false });

// Side Scrollbar
let scrollLastY = 0;
sideScroll.addEventListener("touchstart", (e) => {
  e.preventDefault();
  scrollLastY = e.touches[0].clientY;
  vibrate(10);
}, { passive: false });

sideScroll.addEventListener("touchmove", (e) => {
  e.preventDefault();
  const currentY = e.touches[0].clientY;
  const dy = currentY - scrollLastY;
  if (Math.abs(dy) > 2) {
    sendCommand({ type: "scroll", dy: -dy * 0.15, dx: 0 });
    scrollLastY = currentY;
  }
}, { passive: false });

// Tombol Mouse Fisik
btnLeftClick.addEventListener("touchstart", (e) => {
  e.preventDefault();
  vibrate(15);
  btnLeftClick.classList.add("active");
  sendCommand({ type: "mouse_down", button: "left" });
});
btnLeftClick.addEventListener("touchend", (e) => {
  e.preventDefault();
  btnLeftClick.classList.remove("active");
  sendCommand({ type: "mouse_up", button: "left" });
});

btnRightClick.addEventListener("click", () => {
  vibrate(20);
  sendCommand({ type: "click", button: "right" });
});

// ================= KEYBOARD & SHORTCUTS =================
btnSendText.addEventListener("click", sendTypedText);
keyboardInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    sendTypedText();
  }
});

function sendTypedText() {
  const text = keyboardInput.value;
  if (text) {
    sendCommand({ type: "type_text", text: text });
    keyboardInput.value = "";
    vibrate(12);
  }
}

document.querySelectorAll(".key-btn[data-key]").forEach((btn) => {
  btn.addEventListener("click", () => {
    const key = btn.getAttribute("data-key");
    vibrate(15);
    sendCommand({ type: "key_press", key: key });
  });
});

document.querySelectorAll(".key-btn[data-hotkey]").forEach((btn) => {
  btn.addEventListener("click", () => {
    const hotkeyStr = btn.getAttribute("data-hotkey");
    const keys = hotkeyStr.split(",");
    vibrate(20);
    sendCommand({ type: "hotkey", keys: keys });
  });
});

// ================= MEDIA & POWER =================
document.querySelectorAll(".action-btn[data-media]").forEach((btn) => {
  btn.addEventListener("click", () => {
    const action = btn.getAttribute("data-media");
    vibrate(15);
    sendCommand({ type: "media", action: action });
  });
});

document.querySelectorAll(".action-btn[data-power]").forEach((btn) => {
  btn.addEventListener("click", () => {
    const action = btn.getAttribute("data-power");
    vibrate(25);

    if (action === "shutdown" || action === "restart") {
      const confirmAction = confirm(`Yakin ingin melakukan ${action.toUpperCase()} pada komputer?`);
      if (!confirmAction) return;
      document.getElementById("btnCancelShutdown").style.display = "block";
    }

    if (action === "cancel") {
      document.getElementById("btnCancelShutdown").style.display = "none";
    }

    sendCommand({ type: "power", action: action, delay: 5 });
  });
});

// ================= LIVE SCREEN =================
let streamActive = true;

btnToggleStream.addEventListener("click", () => {
  streamActive = !streamActive;
  btnToggleStream.textContent = streamActive ? "Jeda Stream" : "Mulai Stream";
  screenImg.src = streamActive ? "/stream.mjpg" : "";
  vibrate(15);
});

screenWrapper.addEventListener("click", (e) => {
  const rect = screenImg.getBoundingClientRect();
  const clickX = e.clientX - rect.left;
  const clickY = e.clientY - rect.top;

  if (clickX >= 0 && clickX <= rect.width && clickY >= 0 && clickY <= rect.height) {
    const normX = clickX / rect.width;
    const normY = clickY / rect.height;
    vibrate(15);
    sendCommand({
      type: "tap_coordinate",
      x: normX,
      y: normY,
      button: "left",
    });
  }
});

btnFullscreen.addEventListener("click", () => {
  vibrate(10);
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen().catch(() => {});
  } else {
    document.exitFullscreen().catch(() => {});
  }
});

// ================= REMOTE TERMINAL / CMD =================
const cmdInput = document.getElementById("cmdInput");
const btnRunCmd = document.getElementById("btnRunCmd");
const terminalConsole = document.getElementById("terminalConsole");
const btnClearTerminal = document.getElementById("btnClearTerminal");

function appendTerminalOutput(command, output, success = true) {
  if (!terminalConsole) return;

  const cmdEl = document.createElement("div");
  cmdEl.className = "term-line prompt";
  cmdEl.textContent = `C:\\> ${command}`;
  terminalConsole.appendChild(cmdEl);

  const outEl = document.createElement("div");
  outEl.className = `term-line ${success ? "output" : "error"}`;
  outEl.textContent = output;
  terminalConsole.appendChild(outEl);

  terminalConsole.scrollTop = terminalConsole.scrollHeight;
  vibrate(15);
}

function executeCmd() {
  const cmd = cmdInput.value.trim();
  if (!cmd) return;

  vibrate(15);
  sendCommand({ type: "cmd_exec", command: cmd });
  cmdInput.value = "";
}

if (btnRunCmd) {
  btnRunCmd.addEventListener("click", executeCmd);
}

if (cmdInput) {
  cmdInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      executeCmd();
    }
  });
}

document.querySelectorAll(".cmd-pill").forEach((pill) => {
  pill.addEventListener("click", () => {
    const cmd = pill.getAttribute("data-cmd");
    if (cmd) {
      if (cmdInput) cmdInput.value = cmd;
      executeCmd();
    }
  });
});

if (btnClearTerminal) {
  btnClearTerminal.addEventListener("click", () => {
    if (terminalConsole) {
      terminalConsole.innerHTML =
        '<div class="term-line info">Microsoft Windows [Terminal Bersih]</div>';
    }
  });
}

window.addEventListener("load", () => {
  connectWebSocket();
});
