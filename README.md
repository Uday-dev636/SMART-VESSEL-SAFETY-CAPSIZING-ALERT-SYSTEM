# SMART-VESSEL-SAFETY-CAPSIZING-ALERT-SYSTEM
oT-based boat safety system for fishermen that detects dangerous tilt using an MPU6050 sensor. An ESP32 triggers a buzzer and sends real-time alerts with GPS location via LoRa to nearby boats. An OLED display shows live data and warnings for quick response.

# 🚤 IoT-Based Boat Safety & Communication System

## Overview
This project is an IoT-based safety system designed for fishermen operating in the sea. It continuously monitors boat tilt using sensors and detects dangerous conditions that may lead to capsizing.

When a risky tilt is detected, the system triggers a local buzzer alert and sends real-time warning messages along with GPS location to nearby boats using LoRa communication.

---

## Problem Statement
Fishermen face serious risks in the ocean due to strong waves, sudden storms, and boat instability. In emergency situations, there is often no fast communication system available between nearby boats.

---

## Solution
A low-cost IoT-based system that detects dangerous boat tilt and provides real-time alerts using LoRa communication, helping nearby boats respond quickly and prevent accidents.

---

## Objectives
- Monitor boat tilt in real time  
- Detect dangerous tilt conditions  
- Provide instant alert using buzzer  
- Send emergency messages to nearby boats  
- Share GPS location for rescue support  

---

## Components Used
- ESP32 (Main Controller)  
- MPU6050 (Tilt Sensor - Accelerometer & Gyroscope)  
- LoRa SX1278 Module (Wireless Communication)  
- NEO-6M GPS Module (Location Tracking)  
- OLED Display (SSD1306)  
- Buzzer  
- Power Supply  

---

## System Architecture
The system consists of two main modules:

### Sender Boat
- MPU6050 detects tilt  
- ESP32 processes data  
- GPS provides location  
- LoRa sends alert message  

### Receiver Boat
- LoRa receives signal  
- ESP32 processes message  
- OLED displays alert  
- Buzzer gives warning  

### Data Flow:
Sensor → ESP32 → LoRa → Nearby Boat → OLED Display → User

---

## Working
- MPU6050 continuously monitors boat tilt  
- ESP32 calculates tilt angle  
- If tilt exceeds safe threshold:
  - Buzzer alert is activated  
  - Alert message is generated  
- GPS module provides location data  
- LoRa transmits alert to nearby boats  
- Receiver boat displays alert on OLED  
- Nearby fishermen can respond quickly  

---

## Simulation (Processing Software)
To better visualize boat behavior in ocean conditions, we used the Processing software to create a simulation.

The simulation represents boat movement based on tilt data, helping to understand how the system reacts to waves and unstable conditions. It provides a visual demonstration of how the boat tilts and how alerts are triggered in real time.

This improves testing, presentation, and understanding of the system without requiring real ocean conditions.

---

## Hardware Connections
Detailed pin connections: `docs/connections.md`

---

## Results
(Add your project images here)

---

## Features
- Real-time tilt monitoring  
- Immediate danger alert system  
- Long-range LoRa communication  
- GPS-based location sharing  
- OLED display for live alerts  
- Low-cost and efficient design  

---

## Observations
- System responds quickly to tilt changes  
- LoRa communication works over long distances  
- Accurate tilt detection improves safety  
- Works without internet connectivity  

---

## Future Improvements
- Weather monitoring integration  
- GSM-based emergency alerts  
- Mobile app for monitoring  
- AI-based danger prediction  

---

## Documentation
- Hardware Connections: `docs/connections.md`  
- System Working: `docs/working.md`  
- System Architecture: `docs/architecture.md`  

---

## Author
Abhi  
Electronics & Communication Engineering Student
