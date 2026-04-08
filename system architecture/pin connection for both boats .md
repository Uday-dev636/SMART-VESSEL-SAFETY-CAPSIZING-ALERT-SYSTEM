## Sender Boat Connections

---

### MPU6050 (Tilt Sensor - I2C)
- VCC → 3.3V  
- GND → GND  
- SDA → GPIO 21  
- SCL → GPIO 22  

**Note:**  
Uses I2C communication and shares the same bus with OLED.

---

### OLED Display (SSD1306 - I2C)
- VCC → 3.3V  
- GND → GND  
- SDA → GPIO 21  
- SCL → GPIO 22  

---

### LoRa Module (SX1278 RA-02 - SPI)
- VCC → 3.3V 
- GND → GND  
- MISO → GPIO 19  
- MOSI → GPIO 23  
- SCK → GPIO 18  
- NSS (CS) → GPIO 5  
- RST → GPIO 14  
- DIO0 → GPIO 2  

**Note:**  
LoRa must be powered with 3.3V only.

---

### 🔹 GPS Module (NEO-6M - UART)
- VCC → 3.3V / 5V  
- GND → GND  
- TX → GPIO 16  
- RX → GPIO 17  

---

### GSM Module (SIM800L - UART)
- VCC → 3.7V Battery 
- GND → GND  
- TX → GPIO 26  
- RX → GPIO 27  

**Note:**  
Requires stable external power supply.

---

### Buzzer
- VCC → GPIO 25  
- GND → GND  

---

## Receiver Boat Connections

---

### OLED Display (SSD1306 - I2C)
- VCC → 3.3V  
- GND → GND  
- SDA → GPIO 21  
- SCL → GPIO 22  

---

###  LoRa Module (SX1278 RA-02 - SPI)
- VCC → 3.3V  
- GND → GND  
- MISO → GPIO 19  
- MOSI → GPIO 23  
- SCK → GPIO 18  
- NSS (CS) → GPIO 5  
- RST → GPIO 14  
- DIO0 → GPIO 2  

---

###  Buzzer (Optional)
- VCC → GPIO 25  
- GND → GND  

---

###  I2C Configuration (Both Boats)
- SDA → GPIO 21  
- SCL → GPIO 22  

---

##  Important Notes
- LoRa works only on 3.3V  
- SIM800L needs a 3.7V battery  
- I2C devices share GPIO 21 & 22  
- Antenna must be connected  
- Same LoRa frequency required (433E6)
