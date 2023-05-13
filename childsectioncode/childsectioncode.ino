// CHILD SECTION CODE - 8266 NODEMCU

#include <ESP8266WiFi.h>
#include <espnow.h>
#include <PubSubClient.h>
#include <ESP8266HTTPClient.h>
#include <Preferences.h>
#include <Arduino_JSON.h>
#include <TinyGPS++.h> // library for GPS module
#include <SoftwareSerial.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#define heartratePin A0
#include "DFRobot_Heartrate.h"

DFRobot_Heartrate heartrate(DIGITAL_MODE);
TinyGPSPlus gps;  // The TinyGPS++ object
SoftwareSerial ss(4, 3);
float latitude , longitude;
String  lat_str , lng_str;

char msg_lat[20];
char msg_lon[20];

const char *ssid = "hacker"; // Enter your WiFi name
const char *password = "123123123";  // Enter WiFi password

String serverName = "http://google.com/";
#define API_KEY "AIzaSyAE9Nq-RB3RPMnryWh93woN7_F3V-evVx8"
#define DATABASE_URL "https://minion-b3d00-default-rtdb.firebaseio.com/" 
FirebaseData fbdo;

FirebaseAuth auth;
FirebaseConfig config;
unsigned long sendDataPrevMillis = 0;
int intValue;
float floatValue;
bool signupOK = false;
char test;
// MQTT Broker -- cloud communication
const char *mqtt_broker = "broker.emqx.io";
const char *topic = "minion/childsectiondata";
const char *topic1="minion/latitude";
const char *topic2="minion/longitude";
const char *mqtt_username = "emqx";
const char *mqtt_password = "public";
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

uint8_t broadcastAddress[] = {0xC0,0x49,0xEF,0xCC,0x21,0x74};
int status_code;
// Structure example to send data
// Must match the receiver structure
typedef struct struct_message {
  float a;
  float b;
  int c;
} struct_message;

int sensorValue2 = 0;
int sensorPin = A0;

//typedef struct struct_message_rainsensor_data {
//  int watersensor_data;
//} struct_message_rainsensor_data;

// Create a struct_message called myData
struct_message myData;

//struct_message_rainsensor_data myData2;

unsigned long lastTime = 0;  
unsigned long timerDelay = 2000;  // send readings timer

// setting a variable threshold

float threshold = -75;


// Callback when data is sent
void OnDataSent(uint8_t *mac_addr, uint8_t sendStatus) {
 // Serial.print("Last Packet Send Status: ");
  if (sendStatus == 0){
  //  Serial.println("Delivery success");
  }
  else{
  //  Serial.println("Delivery fail");
  }
}


void setup() {
  // Init Serial Monitor
  Serial.begin(115200);
  ss.begin(9600);

  //CONNECTING TO WIFI
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
 //   Serial.println("Connecting to WiFi..");
  }
//  Serial.println("Connected to wifi");

    client.setServer(mqtt_broker, mqtt_port);
   
   while (!client.connected()) {
     String client_id = "esp32-client-";
     client_id += String(WiFi.macAddress());
   //  Serial.printf("The client %s connects to the public mqtt broker\n", client_id.c_str());
     if (client.connect(client_id.c_str(), mqtt_username, mqtt_password)) {
    //     Serial.println("Public emqx mqtt broker connected");
     } else {
   //      Serial.print("failed with state ");
    //     Serial.print(client.state());
         delay(2000);
     }
 }
 config.api_key = API_KEY;
 config.database_url = DATABASE_URL;

 if (Firebase.signUp(&config, &auth, "", "")) {
  //  Serial.println("ok");
    signupOK = true;
  }
  else {
 //   Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }
  config.token_status_callback = tokenStatusCallback; //see addons/TokenHelper.h

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Set device as a Wi-Fi Station
  WiFi.mode(WIFI_STA);

  // Init ESP-NOW
  if (esp_now_init() != 0) {
  //  Serial.println("Error initializing ESP-NOW");
    return;
  }

  // Once ESPNow is successfully Init, we will register for Send CB to
  // get the status of Trasnmitted packet
  esp_now_set_self_role(ESP_NOW_ROLE_CONTROLLER);
  esp_now_register_send_cb(OnDataSent);
  
  // Register peer
  esp_now_add_peer(broadcastAddress, ESP_NOW_ROLE_SLAVE, 1, NULL, 0);
  
}




void loop() {
  status_code=waterdetection();
  Serial.println(status_code);
  if ((millis() - lastTime) > timerDelay) {
    // Set values to send
    myData.a=WiFi.RSSI();
   // Serial.println(myData.a);
    myData.b=threshold;
    myData.c=status_code;       
    // Send message via ESP-NOW
    esp_now_send(broadcastAddress, (uint8_t *) &myData, sizeof(myData));

    // fetching threshold value from firebase 

    if (Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 15000 || sendDataPrevMillis == 0)) {
    sendDataPrevMillis = millis();
    if (Firebase.RTDB.getInt(&fbdo, "todos/100/Threshold")) {
      if (fbdo.dataType() == "int") { 
        intValue = fbdo.intData();
    //    Serial.println(intValue);
        threshold=intValue;
      }
    }
    else {
    //  Serial.println(fbdo.errorReason());
    //  Serial.println("Hey failed to fetch value");
    }
  }
    
   // Serial.println(threshold);
  
 
    // checking the internet availability

    if (!client.connected()) {
   // Serial.println("Connecting to MQTT broker...");
    if (client.connect("ESP32Client")) {
  //    Serial.println("Connected to MQTT broker");
    } else {
   //   Serial.println("Connection failed");
      delay(5000);
      return;
    }
    }
    
   //   Serial.println(WiFi.RSSI());
      if(WiFi.RSSI()<=threshold){
         client.publish(topic, "500");
         client.subscribe(topic);
       }else{
            delay(1000);
            client.publish(topic, "300");
    }
    lastTime = millis();
  }




  
//  GPS READING 
  while (ss.available() > 0)
    if (gps.encode(ss.read())) //read gps data
    {
      if (gps.location.isValid()) //check whether gps location is valid
      {
        latitude = gps.location.lat();
        lat_str = String(latitude , 6);
        if (Firebase.RTDB.setString(&fbdo, "minion/latitude", lat_str)){
        }
        longitude = gps.location.lng();
        lng_str = String(longitude , 6);
        if (Firebase.RTDB.setString(&fbdo, "minion/longitude", lng_str)){

       }
        delay(2000);
      }
    }       
}




int waterdetection(){

delay(500);
sensorValue2 = analogRead(sensorPin);
sensorValue2 = constrain(sensorValue2, 150, 440); 
sensorValue2 = map(sensorValue2, 150, 440, 1023, 0); 
if (sensorValue2>= 20)
{
  Serial.print("rain is detected");
  
  if (Firebase.RTDB.setString(&fbdo, "water/statusCode", "600")){
  }
  return 600;
  }
  else{
    if (Firebase.RTDB.setString(&fbdo, "water/statusCode", "0")){
    }
    return 0;
    
   }
  
{
  
  Serial.print("rain not detected"); 
  }
Serial.println();
delay(100);
  
}
