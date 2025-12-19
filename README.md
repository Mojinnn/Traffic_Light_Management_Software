# Traffic Light Management Software

## Overview

Traffic Light Management Software is a smart traffic control system that combines **software, hardware, and AI** to monitor, manage, and optimize traffic light operations at intersections. The project integrates backend services, a web-based frontend, IoT devices (ESP32/ESP‑CAM), and optional AI models for traffic analysis.

This repository is adapted and extended from an existing traffic system project and customized to support real-time monitoring, configuration, and control of traffic lights.

---

## System Architecture

The system consists of four main components:

1. **Backend Application**

   * Handles traffic logic and configuration
   * Communicates with database and hardware devices
   * Exposes APIs for frontend interaction

2. **Frontend (Web UI)**

   * Displays traffic status and density
   * Allows configuration and management of traffic lights

3. **Hardware / IoT Layer**

   * ESP32 / ESP‑CAM devices
   * Uses MQTT to transmit images or traffic data

4. **AI Module**

   * Processes camera data
   * Estimates traffic density or detects congestion

---

## 📂 Project Structure

```
Traffic_Light_Management_Software/
│
├── app/                    # Backend application logic
├── fe/                     # Frontend web application
├── hardware/
│   └── esp_cam_mqtt/       # ESP‑CAM + MQTT firmware
├── AI model/               # AI models for traffic analysis
├── stream/                 # Video or data streaming components
│
├── traffic.db              # SQLite database
├── traffic_config.json     # Traffic light configuration file
├── requirements.txt        # Python dependencies
├── package.json            # Node.js dependencies
├── Procfile                # Deployment configuration
├── runtime.txt             # Runtime environment settings
└── README.md               # Project documentation
```

---

## ⚙️ Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Mojinnn/Traffic_Light_Management_Software.git
cd Traffic_Light_Management_Software
```

### 2. Backend Setup (Python)

```bash
python -m venv venv
source venv/bin/activate      # Windows: venv\\Scripts\\activate
pip install -r requirements.txt
```

Run the backend server (example):

```bash
python app/main.py
```

### 3. Frontend Setup

```bash
cd fe
npm install
npm start
```

### 4. Configuration

* Edit `traffic_config.json` to adjust traffic light timing and behavior
* `traffic.db` stores intersection and traffic data

### 5. Hardware Setup (ESP‑CAM)

* Configure WiFi and MQTT broker settings in `hardware/esp_cam_mqtt`
* Flash firmware to ESP‑CAM
* Ensure MQTT broker is running and reachable by the backend

---

## Deployment
We deployed this project on [this website](https://traffic-system-3.onrender.com/). Everybody can experience.
