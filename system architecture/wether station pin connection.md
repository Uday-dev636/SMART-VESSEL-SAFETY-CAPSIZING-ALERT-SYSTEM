## Weather Station Connections

### DHT22 (Temperature & Humidity Sensor)
- VCC → 3.3V  
- GND → GND  
- DATA → GPIO 4  

**Note:**  
A 10k pull-up resistor is required between VCC and DATA for stable readings.

---

### BMP280 (Pressure Sensor - I2C)
- VCC → 3.3V  
- GND → GND  
- SDA → GPIO 21  
- SCL → GPIO 22  

---

### I2C Configuration
The BMP280 uses I2C communication and can share the same SDA and SCL pins with other I2C devices such as OLED display or MPU6050.

- SDA → GPIO 21  
- SCL → GPIO 22  

---

