#include <WaspSensorCities_PRO.h>
#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <Wasp4G.h>


// APN settings
///////////////////////////////////////
char apn[] = "";    //(access pofloat name) for gateway
char login[] = "";
char password[] = "";
///////////////////////////////////////

// SERVER settings
///////////////////////////////////////
char host[] = "test.libelium.com";
uint16_t port = 80;
char resource[] = "/test-get-post.php";
///////////////////////////////////////


//declared global vars
float Concentration;
float Temperature;
float Humidity;
float Pressure;
int   error;

//initialized global vars
Gas gas_Pro(SOCKET_C);
char node_ID[] = "GP_CEDAR_TEST_0";


void setup()
{
  USB.ON();
  RTC.ON();

  USB.println(F("Start program"));
  USB.println(F("********************************************************************"));
  USB.println(F("POST method to the Libelium's test url"));
  USB.println(F("You can use this php to test the HTTP connection of the module."));
  USB.println(F("The php returns the parameters that the user sends with the URL."));
  USB.println(F("********************************************************************"));
  
  //setting Sensor ID
  frame.setID(node_ID);
  delay(800);

  //turn on the socket holding H2S and temp probe respectively
  SensorCitiesPRO.ON(SOCKET_C);
  SensorCitiesPRO.ON(SOCKET_B);

  //Powers on the H2S sensor
  gas_Pro.ON();
  USB.println(F("warming up H2S Sensor.."));
  //Gives the sensor time to warm up. RTC will wake up waspmote after time given
  PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
  USB.println(F("H2S warmed up"));
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
  // 4. ready access point for reception
  ///////////////////////////////////////////

  readyAPN();

  ///////////////////////////////////////////
  // 5. send frame via http post
  ///////////////////////////////////////////

  sendFrame();

  ///////////////////////////////////////////
  // 6. Sleep
  ///////////////////////////////////////////

  USB.println(F("Entering Deep Sleep"));
  PWR.deepSleep("00:00:00:20", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);
}

//reads in values via probes
void readValues()
{
  USB.println(F("Reading Values.."));

  Concentration = gas_Pro.getConc();
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

//prepares the access pofloat and shows the settings given to it
void readyAPN()
{
  USB.println(F("prepping APN.."));
  _4G.set_APN(apn, login, password);

  //show APN settings via USB port
  USB.println(F("displaying APN settings"));
  _4G.show_APN();
}


//sends a frame of collected values to the selected URL
void sendFrame()
{
  error = _4G.ON();

  if (error == 0)
  {
    USB.println(F("4G module ready..."));
    USB.print(F("attempting HTTP POST request: "));

    // send the request, last field uses the frame as the data item being sent
    error = _4G.http( Wasp4G::HTTP_POST, host, port, resource, (char*) frame.buffer);

    // check the answer
    if (error == 0)
    {
      USB.print(F("Done. HTTP code: "));
      USB.println(_4G._httpCode);
      USB.print("Server response: ");
      USB.println(_4G._buffer, _4G._length);
    }
    else
    {
      USB.print(F("Failed. Error code: "));
      USB.println(error, DEC);
    }
  }
  else
  {
    // Problem with the communication with the 4G module
    USB.println(F("4G module not started"));
    USB.print(F("Error code: "));
    USB.println(error, DEC);
  }

  USB.println(F("***************************************"));

  // 3. Powers off the 4G module
  _4G.OFF();
}







