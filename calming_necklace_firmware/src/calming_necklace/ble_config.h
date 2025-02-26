// ble_config.h

#ifndef BLE_CONFIG_H
#define BLE_CONFIG_H

#include <ArduinoBLE.h>
#include "debug.h"

// Command definitions
#define CMD_LED_ON 1
#define CMD_LED_OFF 2
#define CMD_EMISSION1_DURATION 4
#define CMD_INTERVAL1 6
#define CMD_PERIODIC1 8
#define CMD_HEART_RATE_ENABLED 10
#define CMD_HIGH_HEART_RATE_THRESHOLD 11
#define CMD_LOW_HEART_RATE_THRESHOLD 12

// Service and characteristic UUIDs
#define LED_SERVICE_UUID "19B10000-E8F2-537E-4F6C-D104768A1214"

// Services
extern BLEService ledService;
extern BLEService settingsService;

// Characteristics
extern BLEByteCharacteristic switchCharacteristic;
extern BLEByteCharacteristic keepAliveCharacteristic;
extern BLELongCharacteristic emission1Characteristic;
extern BLELongCharacteristic emission2Characteristic;
extern BLELongCharacteristic interval1Characteristic;
extern BLELongCharacteristic interval2Characteristic;
extern BLEByteCharacteristic periodic1Characteristic;
extern BLEByteCharacteristic periodic2Characteristic;
extern BLEByteCharacteristic heartrateCharacteristic;
extern BLEByteCharacteristic heartRateEnabledCharacteristic;
extern BLEByteCharacteristic highHeartRateThresholdCharacteristic;
extern BLEByteCharacteristic lowHeartRateThresholdCharacteristic;
extern BLEByteCharacteristic heartRateEnabledCharacteristic;
extern BLEByteCharacteristic highHeartRateThresholdCharacteristic;
extern BLEByteCharacteristic lowHeartRateThresholdCharacteristic;

void setupBLE();
void setupServices();
void initializeCharacteristics();
void onCentralConnected(BLEDevice central);
void onCentralDisconnected(BLEDevice central);
void handlePeripheralLoop(BLEDevice central);
void onKeepAliveReceived(BLEDevice central, BLECharacteristic characteristic);

#endif // BLE_CONFIG_H
