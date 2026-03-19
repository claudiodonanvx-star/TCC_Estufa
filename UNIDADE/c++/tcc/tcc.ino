#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// Wi-Fi
const char* ssid = "LUCIANA";
const char* password = "casa75nova";
//const char* ssid = "Dona";
//const char* password = "don@12345";
//const char* ssid = "AMNET_EDUARDO-CASA";
//const char* password = "casa5208";

// API
const char* serverUrl = "http://192.168.0.108:8080/api/validar"; // ajuste conforme IP da sua máquina
//const char* serverUrl = "http://10.44.235.51:8080/api/validar"; // ajuste conforme IP da sua máquina

// DHT11
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// Sensor capacitivo de solo (AOUT)
#define SOIL_PIN 34
const int soloSecoADC = 3200;
const int soloMolhadoADC = 1500;

// LED RGB
#define RED_PIN 14
#define GREEN_PIN 12
#define BLUE_PIN 13

// For common-anode RGB LEDs, set to true to invert channel values.
const bool RGB_COMMON_ANODE = false;

#if defined(ESP32)
const int PWM_FREQ = 5000;
const int PWM_RESOLUTION = 8;

#if !defined(ESP_ARDUINO_VERSION_MAJOR) || (ESP_ARDUINO_VERSION_MAJOR < 3)
const int PWM_CH_RED = 0;
const int PWM_CH_GREEN = 1;
const int PWM_CH_BLUE = 2;
#endif
#endif

int toPwmValue(int value) {
  int clamped = constrain(value, 0, 255);
  return RGB_COMMON_ANODE ? (255 - clamped) : clamped;
}

void blinkColor(int r, int g, int b, int times, int onMs, int offMs) {
  for (int i = 0; i < times; i++) {
    setColor(r, g, b);
    delay(onMs);
    setColor(0, 0, 0);
    delay(offMs);
  }
}

void initRgb() {
#if defined(ESP32)
#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
  ledcAttach(RED_PIN, PWM_FREQ, PWM_RESOLUTION);
  ledcAttach(GREEN_PIN, PWM_FREQ, PWM_RESOLUTION);
  ledcAttach(BLUE_PIN, PWM_FREQ, PWM_RESOLUTION);
#else
  ledcSetup(PWM_CH_RED, PWM_FREQ, PWM_RESOLUTION);
  ledcSetup(PWM_CH_GREEN, PWM_FREQ, PWM_RESOLUTION);
  ledcSetup(PWM_CH_BLUE, PWM_FREQ, PWM_RESOLUTION);
  ledcAttachPin(RED_PIN, PWM_CH_RED);
  ledcAttachPin(GREEN_PIN, PWM_CH_GREEN);
  ledcAttachPin(BLUE_PIN, PWM_CH_BLUE);
#endif
#else
  pinMode(RED_PIN, OUTPUT);
  pinMode(GREEN_PIN, OUTPUT);
  pinMode(BLUE_PIN, OUTPUT);
#endif
}

void setColor(int r, int g, int b) {
  int rv = toPwmValue(r);
  int gv = toPwmValue(g);
  int bv = toPwmValue(b);

#if defined(ESP32)
#if defined(ESP_ARDUINO_VERSION_MAJOR) && (ESP_ARDUINO_VERSION_MAJOR >= 3)
  ledcWrite(RED_PIN, rv);
  ledcWrite(GREEN_PIN, gv);
  ledcWrite(BLUE_PIN, bv);
#else
  ledcWrite(PWM_CH_RED, rv);
  ledcWrite(PWM_CH_GREEN, gv);
  ledcWrite(PWM_CH_BLUE, bv);
#endif
#else
  analogWrite(RED_PIN, rv);
  analogWrite(GREEN_PIN, gv);
  analogWrite(BLUE_PIN, bv);
#endif
}

void testarRgbNoBoot() {
  Serial.println("Teste RGB: vermelho -> verde -> azul -> branco -> apagado");
  setColor(255, 0, 0);
  delay(400);
  setColor(0, 255, 0);
  delay(400);
  setColor(0, 0, 255);
  delay(400);
  setColor(255, 255, 255);
  delay(400);
  setColor(0, 0, 0);
}

void sinalizarConectandoWifi() {
  blinkColor(0, 0, 255, 2, 120, 120);
}

void sinalizarWifiConectado() {
  blinkColor(0, 255, 255, 2, 150, 100);
}

void sinalizarEnvioComSucesso() {
  blinkColor(0, 255, 0, 1, 120, 0);
}

void sinalizarFalhaHttp() {
  blinkColor(255, 0, 0, 3, 120, 120);
}

void sinalizarErroJson() {
  blinkColor(255, 255, 255, 2, 150, 120);
}

void sinalizarErroLeitura() {
  blinkColor(255, 0, 255, 2, 150, 120);
}

float lerUmidadeSoloPercentual() {
  long soma = 0;
  const int amostras = 10;

  for (int i = 0; i < amostras; i++) {
    soma += analogRead(SOIL_PIN);
    delay(20);
  }

  int leituraMedia = soma / amostras;
  float umidadeSolo = (float)(soloSecoADC - leituraMedia) * 100.0 / (soloSecoADC - soloMolhadoADC);

  if (umidadeSolo < 0) umidadeSolo = 0;
  if (umidadeSolo > 100) umidadeSolo = 100;

  return umidadeSolo;
}

void setup() {
  Serial.begin(115200);
  dht.begin();

  pinMode(SOIL_PIN, INPUT);

  initRgb();
  testarRgbNoBoot();

  Serial.println("Conectando ao Wi-Fi...");
  sinalizarConectandoWifi();
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n✅ Conectado ao Wi-Fi!");
  Serial.print("📶 IP do ESP32: ");
  Serial.println(WiFi.localIP());
  sinalizarWifiConectado();
}

void loop() {
  float temperatura = dht.readTemperature();
  float umidade = dht.readHumidity();
  float umidadeSolo = lerUmidadeSoloPercentual();

  if (isnan(temperatura) || isnan(umidade)) {
    Serial.println("⚠️ Erro na leitura do DHT11");
    sinalizarErroLeitura();
    delay(10000);
    return;
  }

  Serial.print("🌡️ Temperatura: ");
  Serial.print(temperatura);
  Serial.println(" °C");

  Serial.print("💧 Umidade: ");
  Serial.print(umidade);
  Serial.println(" %");

  Serial.print("🌱 Umidade do solo: ");
  Serial.print(umidadeSolo);
  Serial.println(" %");

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.setTimeout(6000);
    http.addHeader("Content-Type", "application/json");

    String jsonData = "{\"temperatura\": " + String(temperatura, 2) +
                      ", \"umidade\": " + String(umidade, 2) +
                      ", \"umidadeSolo\": " + String(umidadeSolo, 2) + "}";

    int httpResponseCode = http.POST(jsonData);

    Serial.print("POST em: ");
    Serial.println(serverUrl);
    Serial.print("Payload: ");
    Serial.println(jsonData);

    if (httpResponseCode > 0) {
      String response = http.getString();
      
      Serial.println("📥 Resposta da API:");
      Serial.println(response);

      // Parse JSON
      JsonDocument doc;
      DeserializationError error = deserializeJson(doc, response);

      if (!error) {
        String significado = doc["significado"];
        int r = doc["r"];
        int g = doc["g"];
        int b = doc["b"];

        Serial.print("📘 Significado: ");
        Serial.println(significado);

        Serial.print("🎨 Cor RGB: ");
        Serial.print(r); Serial.print(", ");
        Serial.print(g); Serial.print(", ");
        Serial.println(b);

        sinalizarEnvioComSucesso();
        setColor(r, g, b);
      } else {
        Serial.println("❌ Erro ao interpretar JSON");
        sinalizarErroJson();
        setColor(255, 255, 255);
      }
    } else {
      Serial.print("❌ Erro HTTP: ");
      Serial.println(httpResponseCode);
      sinalizarFalhaHttp();
      setColor(255, 0, 0);
    }

    http.end();
  } else {
    Serial.println("❌ Wi-Fi desconectado");
    sinalizarFalhaHttp();
    setColor(255, 0, 0);

    Serial.println("Tentando reconectar Wi-Fi...");
    sinalizarConectandoWifi();
    WiFi.disconnect();
    WiFi.begin(ssid, password);
    int tentativas = 0;
    while (WiFi.status() != WL_CONNECTED && tentativas < 20) {
      delay(500);
      Serial.print(".");
      tentativas++;
    }
    Serial.println();
    if (WiFi.status() == WL_CONNECTED) {
      Serial.print("Wi-Fi reconectado. IP: ");
      Serial.println(WiFi.localIP());
      sinalizarWifiConectado();
    } else {
      Serial.println("Falha na reconexao Wi-Fi.");
    }
  }

  delay(20000); // Aguarda 20 segundos antes de repetir 
}
