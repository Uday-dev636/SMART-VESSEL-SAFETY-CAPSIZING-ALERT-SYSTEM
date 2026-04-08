#include <Wire.h>
#include <SPI.h>
#include <LoRa.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ================= OLED =================
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// ================= LoRa =================
#define LORA_SS   5
#define LORA_RST  14
#define LORA_DIO0 2

// ================= BUZZER =================
#define BUZZER 25

String receivedData = "";
bool danger = false;

// ===================================================
//   SETUP
// ===================================================
void setup() {
  Serial.begin(115200);

  // ===== I2C =====
  Wire.begin(21, 22);
  delay(500);

  // ===== OLED INIT =====
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED FAIL");
    while (1);
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);

  display.setCursor(0, 0);
  display.println("BOOTING...");
  display.display();
  delay(1000);

  // ===== BUZZER =====
  pinMode(BUZZER, OUTPUT);
  digitalWrite(BUZZER, LOW);

  // ===== LoRa INIT =====
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);

  if (!LoRa.begin(433E6)) {
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("LoRa FAIL!");
    display.display();
    while (1);
  }

  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Receiver Ready");
  display.println("Waiting data...");
  display.display();
}

// ===================================================
//   LOOP
// ===================================================
void loop() {

  int packetSize = LoRa.parsePacket();

  if (packetSize) {

    receivedData = "";

    while (LoRa.available()) {
      receivedData += (char)LoRa.read();
    }

    Serial.println(receivedData);

    // ===== CHECK DANGER =====
    if (receivedData.indexOf("ALERT") >= 0) {
      danger = true;
      digitalWrite(BUZZER, HIGH);
    } else {
      danger = false;
      digitalWrite(BUZZER, LOW);
    }

    // ===== OLED DISPLAY =====
    display.clearDisplay();
    display.setCursor(0, 0);

    if (danger) {
      display.println("!!! DANGER !!!");
    } else {
      display.println("STATUS: SAFE");
    }

    display.println("");

    // Show message nicely
    int len = receivedData.length();

    if (len <= 20) {
      display.println(receivedData);
    } else if (len <= 40) {
      display.println(receivedData.substring(0, 20));
      display.println(receivedData.substring(20));
    } else {
      display.println(receivedData.substring(0, 20));
      display.println(receivedData.substring(20, 40));
      display.println(receivedData.substring(40));
    }

    display.display();
  }
}
