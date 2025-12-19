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

## Deployment
We deployed this project on [this website](https://traffic-system-3.onrender.com/). Everybody can experience.
