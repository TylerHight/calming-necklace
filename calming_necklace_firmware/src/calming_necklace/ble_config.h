// ble_config.h

#ifndef BLE_CONFIG_H
#define BLE_CONFIG_H

#include <ArduinoBLE.h>
#include "debug.h"

// Command definitions
#define CMD_LED_ON 1
#define CMD_LED_OFF 2
#define CMD_EMISSION_DURATION 3  // emission duration
#define CMD_INTERVAL 4  // periodic emission interval
#define CMD_PERIODIC_ENABLED 5
#define CMD_HEART_RATE_ENABLED 6
#define CMD_HIGH_HEART_RATE_THRESHOLD 7
#define CMD_LOW_HEART_RATE_THRESHOLD 8

// Service and characteristic UUIDs
#define LED_SERVICE_UUID "19B10000-E8F2-537E-4F6C-D104768A1214"

// Services
extern BLEService ledService;
extern BLEService settingsService;

// Characteristics
extern BLEByteCharacteristic switchCharacteristic;
extern BLEByteCharacteristic keepAliveCharacteristic;
extern BLELongCharacteristic emission1Characteristic;
extern BLELongCharacteristic interval1Characteristic;
extern BLEByteCharacteristic periodic1Characteristic;
extern BLEByteCharacteristic heartrateCharacteristic;
extern BLEByteCharacteristic heartRateEnabledCharacteristic;
extern BLEByteCharacteristic highHeartRateThresholdCharacteristic;
extern BLEByteCharacteristic lowHeartRateThresholdCharacteristic;

bool setupBLE(uint8_t maxAttempts = 3);
void setupServices();
void initializeCharacteristics();
void onCentralConnected(BLEDevice central);
void onCentralDisconnected(BLEDevice central);
void handlePeripheralLoop(BLEDevice central);
void onKeepAliveReceived(BLEDevice central, BLECharacteristic characteristic);

#endif // BLE_CONFIG_H