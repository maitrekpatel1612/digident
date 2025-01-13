#include <Arduino.h>
#include "esp_camera.h" //  Camera libraries
#include "camera_pins.h"
#include "WiFi.h" // Include the Wi-Fi libraries
#include "WiFiUdp.h"



#define CAMERA_MODEL_AI_THINKER

#define LED_BUILTIN 33 // Define LED_BUILTIN for ESP32

// Wi-Fi AP credentials
const char *ssid = "DigiDent";
const char *password = "12345678";

// Set up UDP
WiFiUDP udp;
unsigned int localUdpPort = 12345; // Local port to listen on


// LOOP CONTROL VARIABLES

bool streaming = false;


// Util Funcs

void lightLog(int times, int delay_ms = 100)
{
    // Assuming the LED_BUILTIN is always on, flashes the LED off for taken values

    for (int i = 0; i < times; i++)
    {
        digitalWrite(LED_BUILTIN, HIGH);
        delay(delay_ms);
        digitalWrite(LED_BUILTIN, LOW);
        delay(delay_ms);
    }
}


void streamImage(IPAddress remoteIP, uint16_t remotePort) {
    
    camera_fb_t* fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("Failed to capture image.");
        return;
    }

    const size_t maxPacketSize = 1024;
    size_t bytesRemaining = fb->len;
    size_t offset = 0;

    // Send image size
    udp.beginPacket(remoteIP, remotePort);
    udp.write((const uint8_t*)&fb->len, sizeof(fb->len));
    udp.endPacket();

    Serial.println("Sent size...");

    // Send image data in chunks
    while (bytesRemaining > 0) {
        size_t chunkSize = (bytesRemaining > maxPacketSize) ? maxPacketSize : bytesRemaining;

        udp.beginPacket(remoteIP, remotePort);
        udp.write(fb->buf + offset, chunkSize);
        udp.endPacket();

        offset += chunkSize;
        bytesRemaining -= chunkSize;
    }

    Serial.println("Sent frame...");
    esp_camera_fb_return(fb);

    delay(50);
}

///////////////////////


void setup()
{
    pinMode(LED_BUILTIN, OUTPUT);
    Serial.begin(115200);
    delay(200);

    // CAM ------------------------------------

    Serial.println("Camera initialising...");
    camera_config_t config;

    // Declaring pins in the config
    {

        config.ledc_channel = LEDC_CHANNEL_0;
        config.ledc_timer = LEDC_TIMER_0;

        config.pin_d0 = Y2_GPIO_NUM;
        config.pin_d1 = Y3_GPIO_NUM;
        config.pin_d2 = Y4_GPIO_NUM;
        config.pin_d3 = Y5_GPIO_NUM;
        config.pin_d4 = Y6_GPIO_NUM;
        config.pin_d5 = Y7_GPIO_NUM;
        config.pin_d6 = Y8_GPIO_NUM;
        config.pin_d7 = Y9_GPIO_NUM;
        config.pin_xclk = XCLK_GPIO_NUM;
        config.pin_pclk = PCLK_GPIO_NUM;
        config.pin_vsync = VSYNC_GPIO_NUM;
        config.pin_href = HREF_GPIO_NUM;
        config.pin_sccb_sda = SIOD_GPIO_NUM; // Replaced `sscb` with `sccb`
        config.pin_sccb_scl = SIOC_GPIO_NUM; // Replaced `sscb` with `sccb`
        config.pin_pwdn = PWDN_GPIO_NUM;
        config.pin_reset = RESET_GPIO_NUM;
        config.xclk_freq_hz = 20000000; // Can be set to 10000000 for slower refresh rate but could lead to stable (slower) execution
        config.pixel_format = PIXFORMAT_JPEG;
    }

    // Initialize the camera
    if (psramFound())
    {
        Serial.println("PSRAM FOUND! Setting framesize to QVGA");
        // config.frame_size = FRAMESIZE_QVGA; // 320x240 resolution
        config.frame_size = FRAMESIZE_VGA; // 640x480 resolution
        config.jpeg_quality = 5;
        config.fb_count = 2;
    }
    else
    {
        Serial.println("PSRAM NOT FOUND! Setting framsize to CIF");
        config.frame_size = FRAMESIZE_CIF;
        config.jpeg_quality = 12; // not 12 (0-63; lower means high quality)
        config.fb_count = 1;
    }

    esp_err_t err = esp_camera_init(&config);

    if (err != ESP_OK)
    {
        Serial.printf("Camera init failed with error 0x%x\n", err);
        return;
    }

    Serial.println("Camera initialized successfully!");
    lightLog(3);


    // WiFi ------------------------------------

    Serial.println("Setting up Access Point (AP)...");
    WiFi.mode(WIFI_AP);     WiFi.softAP(ssid, password, 1, 0, 1);    delay(800);
    
    Serial.println(WiFi.softAPIP());
    lightLog(3);

    udp.begin(localUdpPort);
    Serial.printf("Listening on UDP port %d\n", localUdpPort);
}

// UDP stream Util Vars
char packetBuffer[10];
IPAddress clientIP;

void loop()
{
    int packetSize = udp.parsePacket(); // Check if there’s data to read
    
    if (packetSize)
    {
        // Read incoming packet...
        int len = udp.read(packetBuffer, 10);
        packetBuffer[len] = '\0';

        Serial.print("Recieved: ");
        Serial.println(packetBuffer);

        if (strcmp(packetBuffer, "START") == 0)
        {
            clientIP = udp.remoteIP();
            streaming = true;
            Serial.println("Streaming Started...");
        }else if (strcmp(packetBuffer, "STOP") == 0)
        {
            streaming = false;
            Serial.println("Streaming Stopped...");
        }
    }

    if(streaming){
        Serial.println("STREAMin");
        for (size_t i = 0; i < 5; i++)
        {
            streamImage(clientIP, localUdpPort);
        }
    }
}
