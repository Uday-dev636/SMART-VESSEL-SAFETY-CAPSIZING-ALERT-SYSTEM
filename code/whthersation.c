#include <Wire.h>
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <Adafruit_BMP280.h>
#include <DHT.h>

// -------- TFT --------
#define TFT_CS   D2
#define TFT_DC   D3
#define TFT_RST  D4

Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC, TFT_RST);

// -------- DHT22 --------
#define DHTPIN D6
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// -------- BMP280 --------
Adafruit_BMP280 bmp;

// -------- SETUP --------
void setup() {
  Serial.begin(115200);

  // I2C
  Wire.begin(D2, D1); // SDA, SCL

  // TFT
  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);

  // Sensors
  dht.begin();

  if (!bmp.begin(0x76)) {
    tft.println("BMP280 ERROR!");
    while (1);
  }

  tft.setTextSize(2);
  tft.setTextColor(ILI9341_WHITE);
}

// -------- LOOP --------
void loop() {

  float temp = dht.readTemperature();
  float hum  = dht.readHumidity();
  float pressure = bmp.readPressure() / 100.0;

  tft.fillScreen(ILI9341_BLACK);

  tft.setCursor(10, 10);
  tft.println("Weather Station");

  tft.setCursor(10, 50);
  tft.print("Temp: ");
  tft.print(temp);
  tft.println(" C");

  tft.setCursor(10, 90);
  tft.print("Humidity: ");
  tft.print(hum);
  tft.println(" %");

  tft.setCursor(10, 130);
  tft.print("Pressure: ");
  tft.print(pressure);
  tft.println(" hPa");

  // Cyclone logic
  tft.setCursor(10, 180);

  if (hum < 60 && pressure < 1000) {
    tft.setTextColor(ILI9341_RED);
    tft.println("Cyclone Risk!");
  } else if (hum < 60) {
    tft.setTextColor(ILI9341_YELLOW);
    tft.println("Humidity Drop!");
  } else {
    tft.setTextColor(ILI9341_GREEN);
    tft.println("Weather Normal");
  }

  delay(2000);
}
