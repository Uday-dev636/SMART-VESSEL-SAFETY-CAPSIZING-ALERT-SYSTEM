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

  Wire.begin(21, 22);
  delay(300);

  // OLED
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

  // Buzzer
  pinMode(BUZZER, OUTPUT);
  digitalWrite(BUZZER, LOW);

  // LoRa
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);

  if (!LoRa.begin(433E6)) {
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("LoRa FAIL!");
    display.display();
    while (1);
  }

  // ⚠️ IMPORTANT: keep SAME as transmitter OR remove everywhere
  LoRa.setSpreadingFactor(7);
  LoRa.setSignalBandwidth(125E3);
  LoRa.setCodingRate4(5);

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

    Serial.println("RX: " + receivedData);

    // ✅ FIXED: match transmitter message
    if (receivedData.indexOf("DANGER") >= 0) {
      danger = true;
      digitalWrite(BUZZER, HIGH);
    } else {
      danger = false;
      digitalWrite(BUZZER, LOW);
    }

    // ===== DISPLAY =====
    display.clearDisplay();

    // Title
    display.setTextSize(1);
    display.setCursor(20, 0);
    display.println("LORA GUARD");

    // Status
    display.setTextSize(2);
    display.setCursor(10, 15);

    if (danger) {
      display.println("DANGER");
    } else {
      display.println("SAFE");
    }

    // Divider
    display.drawLine(0, 35, 127, 35, WHITE);

    // Message
    display.setTextSize(1);
    display.setCursor(0, 40);

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
