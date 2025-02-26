// ble_config.cpp

#include "ble_config.h"
#include "led_control.h"
#include "settings.h"
#include "timing.h"
#include "heart_rate.h"
#include "debug.h"

BLEService settingsService("19B10000-E8F2-537E-4F6C-D104768A1214");  // Settings service
BLEService ledService("19b10000-e8f2-537e-4f6c-d104768a1214");  // LED control service

BLEByteCharacteristic switchCharacteristic("19B10001-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite | BLENotify | BLEWriteWithoutResponse);
BLEByteCharacteristic keepAliveCharacteristic("2A3B", BLERead | BLEWrite | BLENotify);
BLELongCharacteristic emission1Characteristic("2A19", BLERead | BLEWrite | BLENotify);
BLELongCharacteristic interval1Characteristic("2A1B", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic periodic1Characteristic("2A1D", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic heartrateCharacteristic("2A1F", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic heartRateEnabledCharacteristic("19B10002-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic highHeartRateThresholdCharacteristic("19B10003-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic lowHeartRateThresholdCharacteristic("19B10004-E8F2-537E-4F6C-D104768A1214", BLERead | BLEWrite | BLENotify);

bool isConnected = false;

void setupBLE() {
    debugPrintln(DEBUG_BLE, "\nInitializing BLE...");

    if (!BLE.begin()) {
        debugPrintln(DEBUG_BLE, "ERROR: Starting BLE failed!");
        while (1);
    }
    
    setupServices();

    BLE.setDeviceName("Calming Necklace");
    BLE.setLocalName("Calming Necklace");
    BLE.setAdvertisedService(ledService);  // Advertise our LED service

    BLE.advertise();
    debugPrintln(DEBUG_BLE, "Advertising as 'Calming Necklace'");
}

void setupServices() {
    ledService.addCharacteristic(switchCharacteristic);
    ledService.addCharacteristic(keepAliveCharacteristic);

    settingsService.addCharacteristic(emission1Characteristic);
    settingsService.addCharacteristic(interval1Characteristic);
    settingsService.addCharacteristic(periodic1Characteristic);
    settingsService.addCharacteristic(heartrateCharacteristic);
    settingsService.addCharacteristic(heartRateEnabledCharacteristic);
    settingsService.addCharacteristic(highHeartRateThresholdCharacteristic);
    settingsService.addCharacteristic(lowHeartRateThresholdCharacteristic);

    BLE.addService(ledService);
    BLE.addService(settingsService);

    initializeCharacteristics();
}

void initializeCharacteristics() {
    switchCharacteristic.writeValue(0);
    keepAliveCharacteristic.writeValue(0);
    emission1Characteristic.writeValue(getEmission1Duration());
    interval1Characteristic.writeValue(getInterval1());
    periodic1Characteristic.writeValue(getPeriodic1Enabled());
    heartrateCharacteristic.writeValue(getCurrentHeartRate());
    heartRateEnabledCharacteristic.writeValue(0);
    highHeartRateThresholdCharacteristic.writeValue(highHeartRateThreshold);
    lowHeartRateThresholdCharacteristic.writeValue(lowHeartRateThreshold);
}

void onCentralConnected(BLEDevice central) {
    debugPrint(DEBUG_BLE, "Connected to central: ");
    debugPrintln(DEBUG_BLE, central.address().c_str());
    digitalWrite(LED_BUILTIN, HIGH);
    resetActivityTimer();
    resetKeepAliveTimer();
    resetHeartRateTimer();
    isConnected = true;
}

void onCentralDisconnected(BLEDevice central) {
    debugPrint(DEBUG_BLE, "Disconnected from central: ");
    debugPrintln(DEBUG_BLE, central.address().c_str());
    digitalWrite(LED_BUILTIN, LOW);
    handleLEDs(CMD_LED_OFF);
    BLE.advertise();
    isConnected = false;
}

void handlePeripheralLoop(BLEDevice central) {
    if (switchCharacteristic.written()) {
        resetActivityTimer();
        handleLEDs(switchCharacteristic.value());
    }

    if (keepAliveCharacteristic.written()) {
        resetKeepAliveTimer();
        onKeepAliveReceived(central, keepAliveCharacteristic);
    }

    handleSettingsUpdate();
    checkPeriodicEmissions();

    if (isConnectionTimedOut() || isKeepAliveTimedOut()) {
        if (isConnected) {
            debugPrintln(DEBUG_BLE, "Connection or keep-alive timeout");
            central.disconnect();
        }
    }
}

void onKeepAliveReceived(BLEDevice central, BLECharacteristic characteristic) {
    uint8_t value = keepAliveCharacteristic.value();
    keepAliveCharacteristic.writeValue(value); // Echo back the value
    resetKeepAliveTimer();
}

void resetBLEState() {
    isConnected = false;
    resetActivityTimer();
    resetKeepAliveTimer();
    resetHeartRateTimer();
}
