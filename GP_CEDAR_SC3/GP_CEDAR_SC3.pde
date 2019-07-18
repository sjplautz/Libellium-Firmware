//Code for Georgia Pacific Environmental Sensors
//

#include <WaspSensorCities_PRO.h>
#include <WaspOPC_N2.h>
#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <WaspLoRaWAN.h>

//////////////////////////////////////////////
uint8_t socket = SOCKET0;                                     //Socket used for LoRaWAN Module
//////////////////////////////////////////////
// Device parameters for Back-End registration
////////////////////////////////////////////////////////////
char DEVICE_EUI[] = "25F06CA4E7BD1389";

// Multitech AEP
//char APP_EUI[] = "6b4eedf07dccb064";
//char APP_KEY[] = "bb41ab6ceedfd216866a38e756867470";

// Multitech SI_000125
char APP_EUI[] = "a832a67c22e23f5f";
char APP_KEY[] = "e5c2d72e7de49194f5d54f806b5278eb";

char nodeID[] = "GP_CEDAR_SC3";                                //Set the NODE ID for this Plug&Sense
char Client_API_KEY[] = "bb41ab6ceedfd216866a38e756867470";     //ClientAPI Key for SI app - required for uploading to SenosrInsight

uint8_t PORT = 82;                                             //Defines which port to use in Back-End: from 1 to 223
uint8_t error;                                                //Error-checking variable

int upcounter = 1;
int downcounter = 1;

Gas gas_PRO_sensor(SOCKET_C);
float LEL_Level;
float Temperature;
float Humidity;
float Pressure;
float TempF;

void sendPacket()
{

  USB.println(F("Creating an ASCII frame"));
  frame.createFrame(ASCII);

  SensorCitiesPRO.ON(SOCKET_C);
  SensorCitiesPRO.ON(SOCKET_B);
 // Gas H2S (SOCKET_C);

  gas_PRO_sensor.ON();


  // H2S Warmup time 2mins
  PWR.deepSleep("00:00:04:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

  LEL_Level = gas_PRO_sensor.getConc();
  Temperature = gas_PRO_sensor.getTemp();
  TempF = ((1.8 * Temperature) + 32);
  Humidity = gas_PRO_sensor.getHumidity();
  Pressure = gas_PRO_sensor.getPressure();


  USB.println(F("***************************************"));
  USB.print(F("Gas concentration: "));
  USB.print(LEL_Level);
  USB.println(F(" % LEL"));
  USB.print(F("Temperature: "));
  USB.print(TempF);
  USB.println(F("Â°F"));
  USB.print(F("RH: "));
  USB.print(Humidity);
  USB.println(F(" %"));
  USB.print(F("Pressure: "));
  USB.print(Pressure);
  USB.println(F(" Pa"));

  frame.createFrame(ASCII);
  frame.addSensor(SENSOR_CITIES_PRO_H2S, LEL_Level);
  frame.addSensor(SENSOR_CITIES_PRO_TF, TempF);
  frame.addSensor(SENSOR_CITIES_PRO_HUM, Humidity);
  frame.addSensor(SENSOR_CITIES_PRO_PRES, Pressure);
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());

  // frame.addSensor(SENSOR_STR, "this_is_a_string");
  //frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
  // frame.addSensor(SENSOR_IN_TEMP, 98.6);
  frame.showFrame();

  //////////////////////////////////////////////
  // 1. Switch on
  //////////////////////////////////////////////
  error = LoRaWAN.ON(socket);                        //Turns LoRaWAN Module ON
  if ( error == 0 )                                  //Check status
  {
    USB.println("1. Switch ON OK");
  } else {
    USB.print("1. Switch ON error = ");
    USB.println(error, DEC);
  }


  //    USB.println("Radio Freq Deviation: " +   LoRaWAN.getRadioFreqDeviation());
  //    USB.println("CRC: " +   LoRaWAN.getRadioCRC());
  //    USB.println("Coding Rate: " +    LoRaWAN.getRadioCR());
  //    USB.println("Bandwidth: " +    LoRaWAN.getRadioBandwidth());
  //    USB.println("Signal to Noise: " +   LoRaWAN.getRadioSNR());
  //    USB.println("ADR: " + LoRaWAN._adr);
  ////    USB.println("Datarate: " + LoRaWAN._dataRate);


  //////////////////////////////////////////////
  // 2. Join network
  //////////////////////////////////////////////
  error = LoRaWAN.joinOTAA();                         //Join network via OTAA
  if ( error == 0 )                                   //Check status
  {
    USB.println("2. Join network OK");



    LoRaWAN.setUpCounter(upcounter);
    LoRaWAN.setDownCounter(downcounter);

    USB.print("upcounter: ");
    USB.println(upcounter);

    error = LoRaWAN.sendConfirmed( PORT, frame.buffer, frame.length);

    //  error = LoRaWAN.sendConfirmed( PORT, data);

    // error = LoRaWAN.sendUnconfirmed( PORT, output);   //Send unconfirmed packet
    //error = LoRaWAN.sendConfirmed( PORT, output);   //Send unconfirmed packet

    // Error messages:
    /*
       '6' : Module hasn't joined a network
       '5' : Sending error
       '4' : Error with data length
       '2' : Module didn't response
       '1' : Module communication error
    */
    if ( error == 0 )                                  //Check status
    {
      USB.println("3. Cconfirmed Packet Sent OK");
      if (LoRaWAN._dataReceived == true)
      {
        USB.print("There's data on port number ");
        USB.print(LoRaWAN._port, DEC);
        USB.print(".\r\n   Data: ");
        USB.println(LoRaWAN._data);
      }
    } else {
      USB.print("Send unconfirmed packet error. Error = ");
      USB.println(error, DEC);
    }
  } else {
    USB.print("2. Join network error = ");
    USB.println(error, DEC);
  }


  USB.print("nwkSKey: ");
  USB.println(LoRaWAN._nwkSKey);
  USB.print("appSKey: ");
  USB.println(LoRaWAN._appKey);

  upcounter++;
  downcounter++;


  //    USB.println("Radio Freq: " +  LoRaWAN.getRadioFrequency());
  ///    USB.println("Radio Freq Deviation: " +   LoRaWAN.getRadioFreqDeviation());
  //   USB.println("CRC: " +   LoRaWAN.getRadioCRC());
  //    USB.println("Coding Rate: " +    LoRaWAN.getRadioCR());
  //    USB.println("Bandwidth: " +    LoRaWAN.getRadioBandwidth());
  //   USB.println("Signal to Noise: " +   LoRaWAN.getRadioSNR());



  //////////////////////////////////////////////
  // 4. Switch off
  //////////////////////////////////////////////
  error = LoRaWAN.OFF(socket);                            //Turn LoRaWAN Module OFF
  if ( error == 0 )                                       //Check status
  {
    USB.println("4. LoRaWAN Module turned OFF.");
  } else {
    USB.print("LoRaWAN Module NOT turned off. Error = ");
    USB.println(error, DEC);
  }

}

void SetLoRaWAN()
{
  USB.println(F("------------------------------------"));
  USB.println(F("  LoRaWAN Module configuration"));
  USB.println(F("------------------------------------\n"));

  //////////////////////////////////////////////
  // 1. Switch on
  //////////////////////////////////////////////
  error = LoRaWAN.ON(socket);                           //Turns the LoRaWAN Module ON
  if ( error == 0 )                                     //Check status
  {
    USB.println("LoRaWAN Module Activated");
  } else {
    USB.print("LoRaWAN Module NOT Activated. Error = ");
    USB.println(error, DEC);
  }

  error = LoRaWAN.factoryReset();
  // Check status
  if ( error == 0 )
  {
    USB.println(F("Reset to factory default values OK"));
  }
  else
  {
    USB.print(F("Reset to factory error = "));
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 2. Set Plug&Sense EUI
  //////////////////////////////////////////////
  error = LoRaWAN.setDeviceEUI(DEVICE_EUI);             //Sets the Plug&Sense's EUI
  if ( error == 0 )                                     //Check status
  {
    LoRaWAN.getDeviceEUI();
    USB.print("2. Plug&Sense EUI set OK. P&S EUI = ");
    USB.println(LoRaWAN._devEUI);
  } else {
    USB.print("2. Plug&Sense EUI NOT set. Error = ");
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 3. Set Application EUI
  //////////////////////////////////////////////
  error = LoRaWAN.setAppEUI(APP_EUI);                  //Sets the Application EUI
  if ( error == 0 )                                    //Check status
  {
    LoRaWAN.getAppEUI();
    USB.print("3. Application EUI set OK. APP EUI = ");
    USB.println(LoRaWAN._appEUI);
  } else {
    USB.print("3. Application EUI NOT set. Error = ");
    USB.println(error, DEC);
  }

  ///////////////////////////////////////
  // 4. Set Application Key
  //////////////////////////////////////
  error = LoRaWAN.setAppKey(APP_KEY);                 //Sets the Application Key
  if ( error == 0 )                                   //Check status
  {
    USB.print("4. APP Key set OK. App Key = ");
    USB.println(LoRaWAN._appKey);
  } else {
    USB.print("4. APP Key NOT set. Error = ");
    USB.println(error, DEC);
  }

  ///////////////////////////////////////
  // 5. Set Channels, ADR, and Retries
  ///////////////////////////////////////
  USB.print("Turn off all Channels");
  for (int ch = 0; ch <= 72; ch++)                      //Disables channels 8 - 64
  {
    error = LoRaWAN.setChannelStatus(ch, "off");      //Check status
    if ( error == 0 )
    {
      // do nothing
    } else {
      USB.print("Ch. ");
      USB.print(ch);
      USB.print(" NOT set to off. Error = ");
      USB.println(error, DEC);
    }
  }

  USB.print("Turn on single subchannel");
  //for (int ch = 0; ch <= 7; ch++)  //if subchannel = 1
  //for (int ch = 8; ch <= 15; ch++)  //if subchannel = 2
  //for (int ch = 16; ch <= 23; ch++)  //if subchannel = 3
  //for (int ch = 24; ch <= 31; ch++)  //if subchannel = 4
  //for (int ch = 32; ch <= 39; ch++)  //if subchannel = 5
  //for (int ch = 40; ch <= 47; ch++)  //if subchannel = 6
  //for (int ch = 48; ch <= 55; ch++)  //if subchannel = 7
  //for (int ch = 56; ch <= 63; ch++)  //if subchannel = 8
  for (int ch = 40; ch <= 47; ch++)
  {
    error = LoRaWAN.setChannelStatus(ch, "on");
    if ( error == 0 )
    {
      // do nothing
    } else {
      USB.print("Ch. ");
      USB.print(ch);
      USB.print(" NOT set to off. Error = ");
      USB.println(error, DEC);
    }
  }

  USB.println(F("\n----------------------------"));

  for ( int i = 0; i < 71; i++)
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

  USB.print("Setting retries...");
  error = LoRaWAN.setRetries(15);                     //Sets Uplink Retry amount
  if ( error == 0 )                                   //Check status
  {
    USB.print("Set Retries for confirmed packets: ");
    USB.println(LoRaWAN.getRetries());
  } else {
    USB.print("Set Retries for confirmed packets error = ");
    USB.println(error, DEC);
  }

  error = LoRaWAN.setADR("on");
  if ( error == 0 )
  {
    USB.print("Adaptive Data Rate enabled OK. ");
    USB.print("ADR: ");
    USB.println(LoRaWAN._adr, DEC);
  } else {
    USB.print("Adaptive Data Rate NOT enabled. Error = ");
    USB.println(error, DEC);
  }

  //////////////////////////////////////////////
  // 6. Save configuration
  //////////////////////////////////////////////
  error = LoRaWAN.saveConfig();                        //Saves Configuration properties
  if ( error == 0 )                                    //Check status
  {
    USB.println("LoRaWAN configuration settings saved. ");
  } else {
    USB.print("LoRaWAN configuration save error. Error = ");
    USB.println(error, DEC);
  }
  USB.println(F("\n------------------------------------"));
  USB.println(F("Module configured"));
  USB.println(F("--------------------------------------"));
}


void setup()
{
  USB.ON();
  USB.println(F("SensorInsight - LoRaWAN Example\n"));
  SetLoRaWAN();
  frame.setID(nodeID);
}

void loop()
{
  sendPacket();
  //delay(30000);
  USB.println(F("Entering Deep Sleep"));
  PWR.deepSleep("00:00:06:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);  //15 minute interval
}





