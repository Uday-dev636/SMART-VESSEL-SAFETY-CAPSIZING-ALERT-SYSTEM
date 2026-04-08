#include <Wire.h>
#include <SPI.h>
#include <LoRa.h>
#include <TinyGPS++.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

TinyGPSPlus gps;
HardwareSerial gpsSerial(1);
HardwareSerial sim800(2);

const int MPU = 0x68;

#define BUZZER    25
#define LORA_SS   5
#define LORA_RST  14
#define LORA_DIO0 2

// ===== TWO THRESHOLDS — key fix =====
float WARNING_THRESHOLD = 30.0;  // yellow warning only — NO buzzer, NO SMS, NO LoRa
float DANGER_THRESHOLD  = 60.0;  // full alarm — buzzer + SMS + LoRa
// =====================================

SemaphoreHandle_t i2cMutex;

volatile float gRoll       = 0;
volatile float gPitch      = 0;
volatile float gSmoothTilt = 0;
volatile float gLat        = 0;
volatile float gLng        = 0;
volatile bool  gGpsValid   = false;
volatile bool  gIsWarning  = false;  // NEW — 30° warning state
volatile bool  gIsDanger   = false;  // 60° danger state
volatile bool  gAlertSent  = false;

float prevTilt = 0;
unsigned long lastAlertTime = 0;
#define ALERT_COOLDOWN 30000

int16_t AcX = 0, AcY = 0, AcZ = 0;

TaskHandle_t Task0;
TaskHandle_t Task1;

// ===================================================
//   CORE 0 — OLED + Serial to Processing
// ===================================================
void coreZeroTask(void * parameter) {
  for (;;) {

    if (xSemaphoreTake(i2cMutex, portMAX_DELAY) == pdTRUE) {
      display.clearDisplay();
      display.setTextSize(1);
      display.setTextColor(WHITE);

      // ── Title bar ──────────────────────────────
      display.fillRect(0, 0, 128, 10, WHITE);
      display.setTextColor(BLACK);
      display.setCursor(18, 1);
      display.print("BOAT TILT MONITOR");
      display.setTextColor(WHITE);

      // ── Tilt value ─────────────────────────────
      display.setCursor(0, 13);
      display.print("TILT: ");
      display.setTextSize(2);
      display.print(gSmoothTilt, 1);
      display.print((char)247);  // degree symbol
      display.setTextSize(1);

      // ── GPS ────────────────────────────────────
      display.setCursor(0, 32);
      if (gGpsValid) {
        display.print("LAT:");
        display.print(gLat, 4);
        display.setCursor(0, 42);
        display.print("LNG:");
        display.print(gLng, 4);
      } else {
        display.print("GPS: Searching...");
        display.setCursor(0, 42);
        display.print("No fix yet");
      }

      // ── Status ─────────────────────────────────
      display.setCursor(0, 54);
      if (gIsDanger) {
        // Blink effect using framecount-style millis
        if ((millis() / 400) % 2 == 0) {
          display.fillRect(0, 53, 128, 11, WHITE);
          display.setTextColor(BLACK);
          display.setCursor(28, 55);
          display.print("!! DANGER !!");
          display.setTextColor(WHITE);
        } else {
          display.setCursor(28, 55);
          display.print("!! DANGER !!");
        }
      } else if (gIsWarning) {
        display.fillRect(0, 53, 128, 11, WHITE);
        display.setTextColor(BLACK);
        display.setCursor(22, 55);
        display.print("-- WARNING --");
        display.setTextColor(WHITE);
      } else {
        display.setCursor(30, 55);
        display.print("STATUS: SAFE");
      }

      display.display();
      xSemaphoreGive(i2cMutex);
    }

    // Send to Processing
    // Format: roll,pitch,tilt,lat,lng,gpsValid
    Serial.print(gRoll, 2);
    Serial.print(",");
    Serial.print(gPitch, 2);
    Serial.print(",");
    Serial.print(gSmoothTilt, 2);
    Serial.print(",");
    Serial.print(gLat, 6);
    Serial.print(",");
    Serial.print(gLng, 6);
    Serial.print(",");
    Serial.println(gGpsValid ? 1 : 0);

    vTaskDelay(100 / portTICK_PERIOD_MS);
  }
}

// ===================================================
//   CORE 1 — Sensors + LoRa + GSM + Buzzer
// ===================================================
void coreOneTask(void * parameter) {
  for (;;) {

    // Read MPU6050
    if (xSemaphoreTake(i2cMutex, portMAX_DELAY) == pdTRUE) {
      Wire.beginTransmission(MPU);
      Wire.write(0x3B);
      Wire.endTransmission(false);
      Wire.requestFrom(MPU, 6, true);
      if (Wire.available() >= 6) {
        AcX = Wire.read() << 8 | Wire.read();
        AcY = Wire.read() << 8 | Wire.read();
        AcZ = Wire.read() << 8 | Wire.read();
      }
      xSemaphoreGive(i2cMutex);
    }

    float ax = AcX / 16384.0;
    float ay = AcY / 16384.0;
    float az = AcZ / 16384.0;

    gRoll  = atan2(ay, az) * 180.0 / PI;
    gPitch = atan2(-ax, sqrt(ay*ay + az*az)) * 180.0 / PI;

    float tilt = max(abs((float)gRoll), abs((float)gPitch));
    gSmoothTilt = 0.7 * prevTilt + 0.3 * tilt;
    prevTilt = gSmoothTilt;

    // GPS
    while (gpsSerial.available()) {
      gps.encode(gpsSerial.read());
    }
    gGpsValid = gps.location.isValid();
    if (gGpsValid) {
      gLat = gps.location.lat();
      gLng = gps.location.lng();
    }

    unsigned long now = millis();

    // ── WARNING at 30° ─────────────────────────────────
    // Only sets flag — NO buzzer, NO SMS, NO LoRa
    if (gSmoothTilt > WARNING_THRESHOLD) {
      gIsWarning = true;
    } else {
      gIsWarning = false;
    }

    // ── DANGER at 60° ──────────────────────────────────
    // Full alarm — buzzer + SMS + LoRa
    if (gSmoothTilt > DANGER_THRESHOLD && gSmoothTilt < 90.0) {
      gIsDanger = true;

      // Buzzer ON only at DANGER (60°), never at warning (30°)
      digitalWrite(BUZZER, HIGH);

      // Send alert with cooldown
      if (!gAlertSent || (now - lastAlertTime > ALERT_COOLDOWN)) {
        sendLoRa(gSmoothTilt, gLat, gLng, gGpsValid);
        sendSMS(gLat, gLng, gGpsValid);
        gAlertSent    = true;
        lastAlertTime = now;
      }

    } else {
      gIsDanger = false;

      // Buzzer OFF when below danger threshold
      digitalWrite(BUZZER, LOW);

      // Reset alert flag with 2° hysteresis to avoid flickering
      if (gSmoothTilt < DANGER_THRESHOLD - 2.0) {
        gAlertSent = false;
      }
    }

    vTaskDelay(50 / portTICK_PERIOD_MS);
  }
}

// ===================================================
//   SETUP
// ===================================================
void setup() {
  Serial.begin(115200);
  Serial.println("[SYS] Starting...");

  i2cMutex = xSemaphoreCreateMutex();

  // MPU6050
  Wire.begin(21, 22);
  delay(200);
  Wire.beginTransmission(MPU);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);
  delay(100);
  Serial.println("[SYS] MPU6050 OK");

  // OLED
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("[ERR] OLED FAIL");
    while (1);
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 0);
  display.println("SYSTEM STARTING...");
  display.setCursor(0, 14);
  display.println("Warning : 30 deg");
  display.setCursor(0, 26);
  display.println("Danger  : 60 deg");
  display.setCursor(0, 40);
  display.println("Initialising...");
  display.display();
  delay(1500);
  Serial.println("[SYS] OLED OK");

  // GPS
  gpsSerial.begin(9600, SERIAL_8N1, 16, 17);
  delay(2000);
  Serial.println("[SYS] GPS OK");

  // GSM
  sim800.begin(9600, SERIAL_8N1, 26, 27);
  delay(1000);
  Serial.println("[SYS] GSM OK");

  // Buzzer
  pinMode(BUZZER, OUTPUT);
  digitalWrite(BUZZER, LOW);
  // Quick test beep so you know buzzer is wired correctly
  digitalWrite(BUZZER, HIGH); delay(100);
  digitalWrite(BUZZER, LOW);
  Serial.println("[SYS] BUZZER OK");

  // LoRa
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  if (!LoRa.begin(433E6)) {
    Serial.println("[ERR] LoRa FAIL");
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("LoRa FAILED!");
    display.println("Check wiring");
    display.display();
    while (1);
  }
  LoRa.setSpreadingFactor(7);
  LoRa.setSignalBandwidth(125E3);
  LoRa.setCodingRate4(5);
  LoRa.setTxPower(20);
  Serial.println("[SYS] LoRa OK");

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("ALL SYSTEMS OK");
  display.setCursor(0, 14);
  display.println("Warn  @ 30 deg");
  display.setCursor(0, 26);
  display.println("Alarm @ 60 deg");
  display.setCursor(0, 40);
  display.println("Monitoring...");
  display.display();
  delay(1000);
  Serial.println("[SYS] ALL READY");

  // Start both tasks
  xTaskCreatePinnedToCore(
    coreZeroTask, "Core0Task",
    10000, NULL, 2, &Task0, 0
  );
  xTaskCreatePinnedToCore(
    coreOneTask, "Core1Task",
    10000, NULL, 1, &Task1, 1
  );
}

void loop() {
  vTaskDelay(1000 / portTICK_PERIOD_MS);
}

// ===================================================
//   SEND SMS
// ===================================================
void sendSMS(float lat, float lng, bool gpsValid) {
  Serial.println("[GSM] Sending SMS...");
  delay(2000);
  sim800.println("AT+CMGF=1");
  delay(1000);
  sim800.println("AT+CMGS=\"+91XXXXXXXXXX\"");  // change to your number
  delay(1000);
  sim800.print("DANGER ALERT!\n");
  sim800.print("Boat tilt exceeded 60 degrees.\n");
  if (gpsValid) {
    sim800.print("Location:\n");
    sim800.print("Lat: "); sim800.print(lat, 6); sim800.print("\n");
    sim800.print("Lng: "); sim800.print(lng, 6); sim800.print("\n");
    sim800.print("Maps: https://maps.google.com/?q=");
    sim800.print(lat, 6);
    sim800.print(",");
    sim800.print(lng, 6);
    sim800.print("\n");
  } else {
    sim800.print("GPS: No fix yet\n");
  }
  sim800.print("Possible capsizing risk!");
  sim800.write(26);  // CTRL+Z to send
  delay(5000);
  Serial.println("[GSM] SMS SENT");
}

// ===================================================
//   SEND LoRa
// ===================================================
void sendLoRa(float tilt, float lat, float lng, bool gpsValid) {
  Serial.println("[LoRa] Sending alert...");
  LoRa.beginPacket();
  LoRa.print("DANGER,");
  LoRa.print("tilt:");
  LoRa.print(tilt, 1);
  LoRa.print(",");
  if (gpsValid) {
    LoRa.print("lat:");
    LoRa.print(lat, 6);
    LoRa.print(",lng:");
    LoRa.print(lng, 6);
  } else {
    LoRa.print("gps:nofix");
  }
  LoRa.endPacket(true);
  Serial.println("[LoRa] Alert SENT");
}
