///////////////////////////////////////////////////////////////////////////////////
//  MODULE FOR SAMPLING GAS AND ENVIRONMENTAL VALUES WITH LORAWAN PROTOCOL SENSOR
//  SETUP TIME: appx. 3 MINUTES
//  SAMPLING CYCLE: appx. 2 MINUTES
//  NODE ID: GP_CEDAR_SC3
///////////////////////////////////////////////////////////////////////////////////

#include <WaspSensorCities_PRO.h>
#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>


//////////////////////////////////////////////
// Device parameters for Back-End registration
//////////////////////////////////////////////
uint8_t socket = SOCKET0;                         //Socket used for LoRaWAN Module
char DEVICE_EUI[] = "25F06CA4E7BD1389";
//////////////////////////////////////////////

// Multitech AEP
//char APP_EUI[] = "6b4eedf07dccb064";
//char APP_KEY[] = "bb41ab6ceedfd216866a38e756867470";

// Multitech SI_000125
char APP_EUI[] = "a832a67c22e23f5f";
char APP_KEY[] = "e5c2d72e7de49194f5d54f806b5278eb";

// SensorInsight Settings
char Client_API_KEY[] = "bb41ab6ceedfd216866a38e756867470";  //ClientAPI Key for SI app - required for uploading to SenosrInsight
uint8_t PORT = 82; //Defines which port to use in Back-End: from 1 to 223

//declared global vars
float Concentration;
float Temperature;
float Humidity;
float Pressure;

// Error messages:
/*
       '6' : Module hasn't joined a network
       '5' : Sending error
       '4' : Error with data length
       '2' : Module didn't response
       '1' : Module communication error
*/
uint8_t error; //Error-checking variable

//initialized global vars
int upcounter = 1;
int downcounter = 1;
int numRetries = 15;
Gas gas_PRO_sensor(SOCKET_C);
char node_ID[] = "GP_CEDAR_SC3"; //Set the NODE ID for this Plug&Sense

void setup()
{
  USB.ON();
  RTC.ON();

  SetLoRaWAN();
  USB.println(F("\n--------START PROGRAM--------"));
  USB.println(F("********************************************************************"));
  USB.println(F("LoRaWAN Test Program"));
  USB.println(F("********************************************************************"));

  //setting Sensor ID
  frame.setID(node_ID);
  delay(800);

  //turn on the socket holding H2S and temp probe respectively
  SensorCitiesPRO.ON(SOCKET_C);
  SensorCitiesPRO.ON(SOCKET_B);

  gas_PRO_sensor.ON();
  USB.println(F("\nwarming up H2S Sensor.."));
  //Gives the sensor time to warm up. RTC will wake up waspmote after time given
  PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  USB.println(F("H2S warmed up"));
}

void SetLoRaWAN()
{
  USB.println(F("\n------------------------------------"));
  USB.println(F("  LoRaWAN Module configuration"));
  USB.println(F("------------------------------------\n"));

  USB.print("Node ID set: Node ID = ");
  USB.println(node_ID);

  //////////////////////////////////////////////
  // 1. Switch on & factory reset
  //////////////////////////////////////////////
  error = LoRaWAN.ON(socket);                           //Turns the LoRaWAN Module ON
  error = LoRaWAN.factoryReset();
  if(error == 0)
  {
    USB.println("\n1. Plug&Sense factory reset OK.");
  }
  else
  {
    USB.println("1. Plug&Sense factory reset failed, error: ");
    USB.print(error);
  }

  //////////////////////////////////////////////
  // 2. Set Plug&Sense EUI
  //////////////////////////////////////////////
  error = LoRaWAN.setDeviceEUI(DEVICE_EUI);             //Sets the Plug&Sense's EUI
  if ( error == 0 )
  {
    LoRaWAN.getDeviceEUI();
    USB.print("2. Plug&Sense EUI set OK. P&S EUI = ");
    USB.println(LoRaWAN._devEUI);
  }

  //////////////////////////////////////////////
  // 3. Set Application EUI
  //////////////////////////////////////////////
  error = LoRaWAN.setAppEUI(APP_EUI);                  //Sets the Application EUI
  if ( error == 0 )
  {
    LoRaWAN.getAppEUI();
    USB.print("3. Application EUI set OK. APP EUI = ");
    USB.println(LoRaWAN._appEUI);
  } 

  ///////////////////////////////////////
  // 4. Set Application Key
  //////////////////////////////////////
  error = LoRaWAN.setAppKey(APP_KEY);                 //Sets the Application Key
  if ( error == 0 )
  {
    USB.print("4. APP Key set OK. App Key = ");
    USB.println(LoRaWAN._appKey);
  }

  ///////////////////////////////////////
  // 5. Set Channels
  ///////////////////////////////////////
  USB.println("\nTurning off all Channels.. ");
  for (int ch = 0; ch <= 71; ch++)                    //Disables channels 8 - 64
  {
    error = LoRaWAN.setChannelStatus(ch, "off"); 
    if ( error != 0 )
    {
      USB.print("\nCh. ");
      USB.print(ch);
      USB.print(" NOT set to off. Error = ");
      USB.println(error, DEC);
    }
  }

  USB.print("\nTurning on single subchannel");
  
  //for (int ch = 0; ch <= 7; ch++)  //if subchannel = 1
  //for (int ch = 8; ch <= 15; ch++)  //if subchannel = 2
  //for (int ch = 16; ch <= 23; ch++)  //if subchannel = 3
  //for (int ch = 24; ch <= 31; ch++)  //if subchannel = 4
  //for (int ch = 32; ch <= 39; ch++)  //if subchannel = 5
  //for (int ch = 40; ch <= 47; ch++)  //if subchannel = 6
  //for (int ch = 48; ch <= 55; ch++)  //if subchannel = 7
  //for (int ch = 56; ch <= 63; ch++)  //if subchannel = 8
  for (int ch = 48; ch <= 55; ch++) //subchannel 7
  {
    error = LoRaWAN.setChannelStatus(ch, "on");
    if ( error != 0 )
    {
      USB.print("Ch. ");
      USB.print(ch);
      USB.print(" NOT set to off. Error = ");
      USB.println(error, DEC);
    }
  }

  ///////////////////////////////////////
  // 6. Display Channels
  ///////////////////////////////////////
  USB.println(F("\n----------------------------"));

  for ( int i = 0; i <= 71; i++)
  {
    LoRaWAN.getChannelFreq(i);
    LoRaWAN.getChannelDRRange(i);
    LoRaWAN.getChannelStatus(i);

    USB.print(F("Channel: "));
    USB.print(i);
    USB.print(F("  Freq: "));
    USB.print(LoRaWAN._freq[i]);
    USB.print(F("  DR min: "));
    USB.print(LoRaWAN._drrMin[i], DEC);
    USB.print(F("  DR max: "));
    USB.print(LoRaWAN._drrMax[i], DEC);
    USB.print(F("  Status: "));
    if (LoRaWAN._status[i] == 1)
    {
      USB.print(F("on"));
    }
    else
    {
      USB.print(F("off"));
    }
    USB.println(F("-"));
  }

  ///////////////////////////////////////
  // 7. Set Retries and ADR
  ///////////////////////////////////////
  USB.print("\nSetting retries to: ");
  USB.println(numRetries);
  LoRaWAN.setRetries(numRetries); //Sets Uplink Retry amount
  
  USB.println("Setting ADR to on...");
  LoRaWAN.setADR("on");
 
  //////////////////////////////////////////////
  // 8. Save configuration
  //////////////////////////////////////////////
  error = LoRaWAN.saveConfig(); //Saves Configuration properties
  if ( error == 0 ) 
  {
    USB.println("\nLoRaWAN configuration settings saved. ");
  } 
  else 
  {
    USB.print("\nLoRaWAN configuration save error. Error = ");
    USB.println(error, DEC);
  }
  
  USB.println(F("------------------------------------"));
  USB.println(F("Module configured"));
  USB.println(F("--------------------------------------"));
}

void loop()
{
  ///////////////////////////////////////////
  // 1. Read sensors
  ///////////////////////////////////////////

  readValues();

  ///////////////////////////////////////////
  // 2. print Values via USB
  ///////////////////////////////////////////

  displayValues();

  ///////////////////////////////////////////
  // 3. Create ASCII frame with values
  ///////////////////////////////////////////

  makeFrame();

  ///////////////////////////////////////////
  // 5. Join Network
  ///////////////////////////////////////////

  joinNetwork();

  ///////////////////////////////////////////
  // 5. send frame via http post
  ///////////////////////////////////////////

  if (error == 0) //if there was no problem joining network then send the frame
  {
    sendFrame();
  }
  
  ///////////////////////////////////////////
  // 6. Sleep
  ///////////////////////////////////////////
  
  USB.println(F("Entering Deep Sleep"));
  PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);  //1 minute interval
}

//reads in values via probes
void readValues()
{
  USB.println(F("\nReading Values.."));

  Concentration = gas_PRO_sensor.getConc();
  Humidity = SensorCitiesPRO.getHumidity();
  Pressure = SensorCitiesPRO.getPressure();
  //temperature is iniitially returned in celsius. Makes use of
  //helper function to convert this value to Farenheight
  Temperature = convertTemp(SensorCitiesPRO.getTemperature());

  USB.println(F("successfully read values"));
}

//helper function which converts a celsius value to farenheight
float convertTemp(float tempIn)
{
  float tempOut = ((1.8 * tempIn) + 32);
  return tempOut;
}

//prints the values of the tested factors to the console
void displayValues()
{
  USB.println(F("***************************************"));
  USB.print(F("Gas concentration: "));
  USB.print(Concentration);
  USB.println(F(" ppm"));
  USB.print(F("Temperature: "));
  USB.print(Temperature);
  USB.println(F(" Farenheight"));
  USB.print(F("Relative Humidity: "));
  USB.print(Humidity);
  USB.println(F("%"));
  USB.print(F("Pressure: "));
  USB.print(Pressure);
  USB.println(F(" Pa"));
  USB.println(F("***************************************"));
}

//builds a new frame which is given the values read by the sensors and then displays
void makeFrame()
{
  USB.println(F("\nbuilding frame.."));

  // Create new frame (ASCII)
  frame.createFrame(ASCII);
  // Add H2S concentration
  frame.addSensor(SENSOR_CITIES_PRO_H2S, Concentration);
  // Add temperature
  frame.addSensor(SENSOR_CITIES_PRO_TF, Temperature);
  // Add humidity
  frame.addSensor(SENSOR_CITIES_PRO_HUM, Humidity);
  // Add pressure
  frame.addSensor(SENSOR_CITIES_PRO_PRES, Pressure);
  // Add battery level
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());

  // Show the frame
  USB.println(F("displaying the resulting frame"));
  frame.showFrame();
}

//Join network via OTAA
void joinNetwork()
{
  LoRaWAN.ON(socket);

  USB.println("\nJoining Network..");

  error = LoRaWAN.joinOTAA();
  if ( error == 0 )
  {
    USB.println("Join network OK");

    LoRaWAN.setUpCounter(upcounter);
    LoRaWAN.setDownCounter(downcounter);

    USB.print("upcounter: ");
    USB.println(upcounter);
    USB.print("downcounter: ");
    USB.println(downcounter);
  }
  else
  {
    USB.print("Join network error = ");
    USB.println(error, DEC);
  }

}

//sends a frame of collected values to the selected port?
void sendFrame()
{
  error = LoRaWAN.sendConfirmed( PORT, frame.buffer, frame.length);
  if ( error == 0 )
  {
    USB.println("3. Cconfirmed Packet Sent OK");
    if (LoRaWAN._dataReceived == true)
    {
      USB.print("There's data on port number ");
      USB.print(LoRaWAN._port, DEC);
      USB.print(".\r\n   Data: ");
      USB.println(LoRaWAN._data);
    }
  }
  else
  {
    USB.print("Send unconfirmed, packet error. Error = ");
    USB.println(error, DEC);
  }

  USB.print("nwkSKey: ");
  USB.println(LoRaWAN._nwkSKey);
  USB.print("appSKey: ");
  USB.println(LoRaWAN._appKey);

  //Turn LoRaWAN Module OFF
  LoRaWAN.OFF(socket);

  upcounter++;
  downcounter++;
}








