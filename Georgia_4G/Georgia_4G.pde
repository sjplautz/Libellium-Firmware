#include <WaspSensorCities_PRO.h>
#include <WaspOPC_N2.h>
#include <WaspSensorGas_Pro.h>
#include <WaspFrame.h>
#include <Wasp4G.h>

Gas gas_PRO_sensor(SOCKET_C);

char node_ID[] = "GP_CEDAR_SC4_MOB";

float LEL_Level;
float Temperature;
float Humidity;
float Pressure;
float TempF;
uint8_t error;
uint8_t gps_status;
float gps_latitude;
float gps_longitude;
uint32_t previous;
bool gps_autonomous_needed = true;


// APN settings
///////////////////////////////////////
char apn[] = "m2m.com.attz";
char login[] = "";
char password[] = "";
///////////////////////////////////////


// SERVER settings
///////////////////////////////////////
char host[] = "integrate.sensorinsight.io";
uint16_t port = 8383;
char resource[] = "/si/lorawan";
///////////////////////////////////////

void sendPacket()
{


  USB.println(F("Creating an ASCII frame"));
  frame.createFrame(ASCII);
  frame.setID(node_ID);


  SensorCitiesPRO.ON(SOCKET_C);
  SensorCitiesPRO.ON(SOCKET_B);
  // Gas H2S (SOCKET_C);
  gas_PRO_sensor.ON();

  // H2S Warmup time 4mins
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
  USB.println(F("°F"));
  USB.print(F("RH: "));
  USB.print(Humidity);
  USB.println(F(" %"));
  USB.print(F("Pressure: "));
  USB.print(Pressure);
  USB.println(F(" Pa"));

  error = _4G.waitForSignal(20000);
  delay(500);

  USB.print(F("3. GPS signal received. Time(secs) = "));
  USB.println((millis() - previous) / 1000);

  USB.println(F("Acquired position:"));
  USB.println(F("----------------------------"));
  USB.print(F("Latitude: "));
  USB.print(_4G._latitude);
  USB.print(F(","));
  USB.println(_4G._latitudeNS);
  USB.print(F("Longitude: "));
  USB.print(_4G._longitude);
  USB.print(F(","));
  USB.println(_4G._longitudeEW);
  USB.print(F("UTC_time: "));
  USB.println(_4G._time);
  USB.print(F("date: "));
  USB.println(_4G._date);
  USB.print(F("Number of satellites: "));
  USB.println(_4G._numSatellites, DEC);
  USB.print(F("HDOP: "));
  USB.println(_4G._hdop);
  USB.println(F("----------------------------"));

  // get degrees
  gps_latitude  = _4G.convert2Degrees(_4G._latitude, _4G._latitudeNS);
  gps_longitude = _4G.convert2Degrees(_4G._longitude, _4G._longitudeEW);

  USB.println("Conversion to degrees:");
  USB.print(F("Latitude: "));
  USB.println(gps_latitude);
  USB.print(F("Longitude: "));
  USB.println(gps_longitude);
  USB.println();



  frame.createFrame(ASCII);
  frame.addSensor(SENSOR_STR, "215bbdd40ed241dea1ca2fa150f567af");
  frame.addSensor(SENSOR_TIME, _4G._time);
  frame.addSensor(SENSOR_DATE, _4G._date);
  frame.addSensor(SENSOR_CITIES_PRO_H2S, LEL_Level);
  frame.addSensor(SENSOR_CITIES_PRO_TF, TempF);
  frame.addSensor(SENSOR_CITIES_PRO_HUM, Humidity);
  frame.showFrame();

  USB.println("Send Frame data");
  error = _4G.http( Wasp4G::HTTP_POST, host, port, resource, (char*) frame.buffer);


  frame.createFrame(ASCII);
  frame.addSensor(SENSOR_STR, "215bbdd40ed241dea1ca2fa150f567af");
  frame.addSensor(SENSOR_TIME, _4G._time);
  frame.addSensor(SENSOR_DATE, _4G._date);
  frame.addSensor(SENSOR_GPS, gps_longitude, gps_latitude);
  frame.addSensor(SENSOR_CITIES_PRO_PRES, Pressure);
  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
  frame.showFrame();
  delay(500);

  USB.println("Send Frame data");
  error = _4G.http( Wasp4G::HTTP_POST, host, port, resource, (char*) frame.buffer);

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

void setup()
{
  USB.ON();
  RTC.ON();
  USB.println(F("H2S Station_1"));
  USB.ON();
  USB.println(F("Start program"));
  delay(800);


}

void loop()
{
  USB.ON();
  RTC.ON();
  delay(800);
  _4G.set_APN(apn, login, password);
  _4G.show_APN();
  error = _4G.ON();
  previous = millis();
  delay(1000);
  gps_status = _4G.gpsStart(Wasp4G::GPS_MS_BASED);
  sendPacket();
  delay(2000);
  PWR.deepSleep("00:00:06:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);//10 minute interval including h2s warmup

}




