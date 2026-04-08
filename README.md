# SMART-VESSEL-SAFETY-CAPSIZING-ALERT-SYSTEM


## Overview
This project is an IoT-based safety and weather monitoring system designed for fishermen at sea. It monitors boat tilt and environmental conditions such as temperature, humidity, and atmospheric pressure.

Using sensors like MPU6050, DHT22, and BMP280, the system detects dangerous tilt and analyzes weather changes to indicate possible storm or cyclone conditions. When a risk is detected, alerts are sent to nearby boats using LoRa communication along with GPS location.



## Problem Statement
Fishermen face serious risks due to strong waves, sudden storms, and a lack of communication at sea. There is no reliable system to detect dangerous boat tilt or monitor weather changes in real time.



## Solution
A low-cost IoT-based system that monitors boat tilt and weather conditions, and sends real-time alerts to nearby boats using LoRa communication, improving safety and emergency response.



## Objectives
- Monitor boat tilt in real time  
- Detect dangerous tilt conditions  
- Monitor weather parameters (temperature, humidity, pressure)  
- Provide early indication of storm or cyclone conditions  
- Send emergency alerts to nearby boats  
- Share GPS location for rescue support  



## Components Used
- ESP32 (Main Controller)  
- MPU6050 (Tilt Sensor - Accelerometer & Gyroscope)  
- DHT22 (Temperature & Humidity Sensor)  
- BMP280 (Pressure Sensor)  
- LoRa SX1278 Module (Wireless Communication)  
- NEO-6M GPS Module (Location Tracking)  
- OLED Display (SSD1306)  
- Buzzer  
- Power Supply  



## System Architecture
The system consists of two main modules:

### Sender Boat
- MPU6050 detects tilt  
- DHT22 & BMP280 monitor weather  
- ESP32 processes data  
- GPS provides location  
- LoRa sends an alert message  

### Receiver Boat
- LoRa receives a signal  
- ESP32 processes the message  
- OLED displays an alert  
- The buzzer gives a warning  

### Data Flow:
Sensors → ESP32 → LoRa → Nearby Boat → OLED Display → User



## Working
- Sensors continuously monitor tilt and weather conditions  
- ESP32 processes sensor data  
- If tilt exceeds safe threshold:
  - Buzzer alert is activated  
  - Alert message is generated  
- Weather data is analyzed for sudden pressure or humidity changes  
- GPS provides real-time location  
- LoRa transmits alerts to nearby boats  
- Receiver boat displays alert on OLED  
- Nearby fishermen can respond quickly  



## Weather Monitoring & Cyclone Detection
The system includes a weather monitoring module using DHT22 and BMP280 sensors.

- DHT22 measures temperature and humidity  
- BMP280 measures atmospheric pressure  

By analyzing sudden drops in pressure and changes in humidity, the system can indicate possible storm or cyclone conditions.

This helps fishermen:
- Identify dangerous weather early  
- Avoid high-risk areas  
- Improve decision-making at sea  



## Simulation (Processing Software)
A Processing-based simulation was developed to visualize boat behavior in ocean conditions.

The simulation represents boat tilt and movement based on sensor data, helping demonstrate how the system reacts to waves and unstable conditions. It improves testing and presentation without requiring real ocean conditions.



## Hardware Connections
Detailed pin connections: `docs/connections.md`



## Results
(Add your project images here)



## Features
- Real-time tilt monitoring  
- Weather monitoring using DHT22 & BMP280  
- Early indication of storm or cyclone conditions  
- Long-range LoRa communication  
- GPS-based location sharing  
- OLED display for live alerts  
- Buzzer alert system  
- Works without internet  



## Observations
- System responds quickly to tilt changes  
- Weather trends help identify risk conditions  
- LoRa works over long distances  
- Accurate readings improve safety  
- Works without internet connectivity  


## Future Improvements
- GSM-based emergency alerts  
- Mobile application integration  
- Cloud data storage  
- AI-based weather prediction  
- Integration with official weather APIs  



## Documentation
- Hardware Connections: `docs/connections.md`  
- System Working: `docs/working.md`  
- System Architecture: `docs/architecture.md`  

---

## Author
Abhi  
Electronics & Communication Engineering Student
