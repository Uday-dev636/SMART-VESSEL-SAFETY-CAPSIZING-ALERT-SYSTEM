#include <Wire.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <Adafruit_BMP280.h>
#include <DHT.h>

// ---------------- TFT PINS ----------------
#define TFT_CS   5
#define TFT_DC   2
#define TFT_RST  4

Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC, TFT_RST);

// ---------------- DHT22 ----------------
#define DHTPIN 15
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// ---------------- BMP280 ----------------
Adafruit_BMP280 bmp;

// ---------------- SETUP ----------------
void setup() {
  Serial.begin(115200);

  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);

  dht.begin();

  if (!bmp.begin(0x76)) {
    Serial.println("BMP280 not found!");
    while (1);
  }

  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
}

// ---------------- LOOP ----------------
void loop() {

  float temp = dht.readTemperature();
  float hum  = dht.readHumidity();
  float pressure = bmp.readPressure() / 100.0; // hPa

  // Clear screen
  tft.fillScreen(ILI9341_BLACK);

  // Title
  tft.setCursor(10, 10);
  tft.setTextSize(2);
  tft.println("Weather Station");

  // Temperature
  tft.setCursor(10, 50);
  tft.print("Temp: ");
  tft.print(temp);
  tft.println(" C");

  // Humidity
  tft.setCursor(10, 90);
  tft.print("Humidity: ");
  tft.print(hum);
  tft.println(" %");

  // Pressure
  tft.setCursor(10, 130);
  tft.print("Pressure: ");
  tft.print(pressure);
  tft.println(" hPa");

  // -------- CYCLONE PREDICTION --------
  tft.setCursor(10, 180);
  tft.setTextSize(2);

  if (hum < 60 && pressure < 1000) {
    tft.setTextColor(ILI9341_RED);
    tft.println("Cyclone Risk!");
  }
  else if (hum < 60) {
    tft.setTextColor(ILI9341_YELLOW);
    tft.println("Humidity Drop!");
  }
  else {
    tft.setTextColor(ILI9341_GREEN);
    tft.println("Weather Normal");
  }

  delay(2000);
}
