
// PARENT SECTION CODE 

#include <WiFi.h>
#include <esp_now.h>
#include <Wire.h>
#include <PubSubClient.h>
#include <HTTPClient.h>
#include <ESP32Ping.h>


//// WiFi
//const char *ssid = "hacker"; // Enter your WiFi name
//const char *password = "123123123";  // Enter WiFi password
//
//// MQTT Broker -- cloud communication
//const char *mqtt_broker = "broker.emqx.io";
//const char *topic1="minion/thresholdvalues";
//const char *mqtt_username = "emqx";
//const char *mqtt_password = "public"; 
//const int mqtt_port = 1883;



//WiFiClient espClient;
//PubSubClient client(espClient);


// off line communication
 const int led_gpio = 32;
 const int led_gpio_safe = 25;
// child section mac address is C0:49:EF:CC:21:74
// 2C:F4:32:14:77:27 parent section mac address
const char* serverName = "";

uint8_t broadcastAddress[] = {0x2C,0xF4,0x32,0x14,0x77,0x27}; // replacing mac address with parent section esp 32

// Define variables to store BME280 readings to be sent
float temperature;
float humidity;
float pressure;

// temp variable to hold the threshold value
float threshold_value = -75;

int water_status;
int heartrate_status_code;
// Define variables to store incoming readings
float incomingTemp;
float incomingHum;
float incomingPres;
bool heart_rate_alert=false;
bool water_detected=false;

String success;  // Variable to store if sending data was successful

typedef struct struct_message {
  float temp;
  float threshold;
  int water_detected;
} struct_message;

typedef struct struct_drowning_data {
  int status_drown;
  
} struct_drowning_data;

typedef struct struct_message_rainsensor_data {
  int water_status;
  
} struct_message_rainsensor_data;

struct_message BME280Readings;

struct_message incomingReadings;// Create a struct_message to hold incoming sensor readings

struct_drowning_data myData_drown;

struct_message_rainsensor_data water_data;

esp_now_peer_info_t peerInfo;


// Callback when data is sent
//void OnDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
//  Serial.print("\r\nLast Packet Send Status:\t");
//  Serial.println(status == ESP_NOW_SEND_SUCCESS ? "Delivery Success" : "Delivery Fail");
//  if (status == 0) {
//    success = "Delivery Success :)";
//  }
//  else {
//    success = "Delivery Fail :(";
//  }
//}

// Callback when data is received-from child section main
void OnDataRecv(const uint8_t * mac, const uint8_t *incomingData, int len) {
  memcpy(&incomingReadings, incomingData, sizeof(incomingReadings));
  Serial.println("Bytes received:.......................................................... ");
  Serial.println(len);
 
    incomingTemp = incomingReadings.temp;
    threshold_value = incomingReadings.threshold;
    water_status = incomingReadings.water_detected;
  
  Serial.println(incomingTemp);
  Serial.println(threshold_value);
  Serial.println(water_status);
  if(incomingTemp <= threshold_value || water_status==600){
    digitalWrite(led_gpio, HIGH);
    delay(1000);
    digitalWrite(led_gpio, LOW);
    delay(1000);
  }else{
   digitalWrite(led_gpio_safe,HIGH);
   delay(1000);
   digitalWrite(led_gpio_safe,LOW);
   delay(1000);
      
  }  
}

//// Callback when data is received-for heart rate
//void OnDataRecv1(const uint8_t * mac, const uint8_t *incomingData, int len) {
//  memcpy(&myData_drown, incomingData, sizeof(myData_drown));
//  Serial.println("Bytes received:.......................................................... ");
//  Serial.println(len);
//  incoming_status = myData_drown.status_drown;
//  Serial.println(incoming_status);
//  if(incoming_status ==800){
//    heart_rate_alert=true;
//  }
//  else{
//    heart_rate_alert=false;
//  }
//}
//
//// Callback when data is received-for rain water sensor
//void OnDataRecv2(const uint8_t * mac, const uint8_t *incomingData, int len) {
//  memcpy(&water_data, incomingData, sizeof(water_data));
//  Serial.println("Bytes received:.......................................................... ");
//  Serial.println(len);
//  incoming_water_status = water_data.water_status;
//  Serial.println(incoming_water_status);
//  if(incoming_water_status==600){
//    water_detected=true;
//  }
//  else{
//    water_detected=false;
//  }
//}

 void setup() {

  Serial.begin(115200);

  //CONNECTING TO WIFI
//  WiFi.begin(ssid, password);
//  while (WiFi.status() != WL_CONNECTED) {
//    delay(500);
//    Serial.println("Connecting to WiFi..");
//  }
//  Serial.println("Connected to wifi");

  
  
  // OFF LINE COMMUNICATION
  pinMode(led_gpio, OUTPUT);
  pinMode(led_gpio_safe, OUTPUT);



 
  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Once ESPNow is successfully Init, we will register for Send CB to
  // get the status of Trasnmitted packet
//  esp_now_register_send_cb(OnDataSent);
  // Register peer
  memcpy(peerInfo.peer_addr, broadcastAddress, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;

  // Add peer
  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("Failed to add peer");
    return;
  }
  esp_now_register_recv_cb(OnDataRecv);
//  esp_now_register_recv_cb(OnDataRecv1);
//  esp_now_register_recv_cb(OnDataRecv2);

//  
//     client.setServer(mqtt_broker, mqtt_port);
//     client.setCallback(callback);
//    while (!client.connected()) {
//     String client_id = "esp32-client-";
//     client_id += String(WiFi.macAddress());
//     Serial.printf("The client %s connects to the public mqtt broker\n", client_id.c_str());
//     if (client.connect(client_id.c_str(), mqtt_username, mqtt_password)) {
//         Serial.println("Public emqx mqtt broker connected");
//     } else {
//         Serial.print("failed with state ");
//         Serial.print(client.state());
//         delay(2000);
//     }
//  }
// client.publish(topic1, "Hi beauty");
// client.subscribe(topic1);
  
}
 
// void callback(char *topic1, byte *payload, unsigned int length) { 
// Serial.print("Message arrived in topic: ");
// //Serial.println(topic1);
// Serial.print("Message:");
// for (int i = 0; i < length; i++) {
//     Serial.print((char)payload[i]);
// }
// Serial.println();
// Serial.println("----------------------- ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,");
//}

void loop() {
 // client.loop();
}
