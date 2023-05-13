
#define heartratePin A0
#include "DFRobot_Heartrate.h"
#include <ESP8266WiFi.h>
#include <espnow.h>
//#include "DHT.h"
#include <SoftwareSerial.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
//#define DHTPIN 2



DFRobot_Heartrate heartrate(DIGITAL_MODE); ///< ANALOG_MODE or DIGITAL_MODE


const char *ssid = "hacker"; // Enter your WiFi name
const char *password = "123123123";  // Enter WiFi password


#define API_KEY "AIzaSyAE9Nq-RB3RPMnryWh93woN7_F3V-evVx8"
#define DATABASE_URL "https://minion-b3d00-default-rtdb.firebaseio.com/" 
FirebaseData fbdo;
unsigned long sendDataPrevMillis = 0;
bool signupOK = false;
FirebaseAuth auth;
FirebaseConfig config;
uint8_t beatvalue;
int sensorValue2 = 0;
int sensorPin = A0;
int rate_value;



unsigned long previousMillis = 0;
const long period = 20;


void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED){
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();


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

}

void loop() {      
     heartrate_data();
     if(Firebase.ready() && signupOK && (millis() - sendDataPrevMillis > 15000 || sendDataPrevMillis == 0)){
      sendDataPrevMillis = millis();
      if (Firebase.RTDB.setString(&fbdo, "test/health", beatvalue)){
      Serial.println("PASSED");
      Serial.println("PATH: " + fbdo.dataPath());
      Serial.println("TYPE: " + fbdo.dataType());
    }
    else {
      Serial.println("FAILED");
      Serial.println("REASON: " + fbdo.errorReason());
    }
     }
}




void heartrate_data(){
      uint8_t rateValue;
     heartrate.getValue(heartratePin); ///< A1 foot sampled values
     rateValue = heartrate.getRate();///< Get heart rate value 
     if(rateValue)  {
       beatvalue=rateValue;
       Serial.println(rateValue); 
     }
      delay(20);
  
}
 
