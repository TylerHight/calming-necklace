// ble_config.cpp

#include "ble_config.h"
#include "led_control.h"
#include "settings.h"
#include "timing.h"

BLEService ledService("180A");
BLEService settingsService("180F");

BLEByteCharacteristic switchCharacteristic("2A57", BLERead | BLEWrite | BLENotify | BLEWriteWithoutResponse);
BLEByteCharacteristic keepAliveCharacteristic("2A3B", BLERead | BLEWrite | BLENotify);
BLELongCharacteristic emission1Characteristic("2A19", BLERead | BLEWrite | BLENotify);
BLELongCharacteristic emission2Characteristic("2A1A", BLERead | BLEWrite | BLENotify);
BLELongCharacteristic interval1Characteristic("2A1B", BLERead | BLEWrite | BLENotify);
BLELongCharacteristic interval2Characteristic("2A1C", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic periodic1Characteristic("2A1D", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic periodic2Characteristic("2A1E", BLERead | BLEWrite | BLENotify);
BLEByteCharacteristic heartrateCharacteristic("2A1F", BLERead | BLEWrite | BLENotify);

bool isConnected = false;

void setupBLE() {
    Serial.println("\nInitializing BLE...");

    if (!BLE.begin()) {
        Serial.println("ERROR: Starting BLE failed!");
        while (1);
    }

    setupServices();

    BLE.setDeviceName("Calming Necklace");
    BLE.setLocalName("Calming Necklace");
    BLE.setAdvertisedService(ledService);

    BLE.advertise();
    Serial.println("Advertising as 'Calming Necklace'");
}

void setupServices() {
    ledService.addCharacteristic(switchCharacteristic);
    ledService.addCharacteristic(keepAliveCharacteristic);

    settingsService.addCharacteristic(emission1Characteristic);
    settingsService.addCharacteristic(emission2Characteristic);
    settingsService.addCharacteristic(interval1Characteristic);
    settingsService.addCharacteristic(interval2Characteristic);
    settingsService.addCharacteristic(periodic1Characteristic);
    settingsService.addCharacteristic(periodic2Characteristic);
    settingsService.addCharacteristic(heartrateCharacteristic);

    BLE.addService(ledService);
    BLE.addService(settingsService);

    initializeCharacteristics();
}

void initializeCharacteristics() {
    switchCharacteristic.writeValue(0);
    keepAliveCharacteristic.writeValue(0);
    emission1Characteristic.writeValue(getEmission1Duration());
    emission2Characteristic.writeValue(getEmission2Duration());
    interval1Characteristic.writeValue(getInterval1());
    interval2Characteristic.writeValue(getInterval2());
    periodic1Characteristic.writeValue(getPeriodic1Enabled());
    periodic2Characteristic.writeValue(getPeriodic2Enabled());
    heartrateCharacteristic.writeValue(getHeartrateThreshold());
}

void onCentralConnected(BLEDevice central) {
    Serial.print("Connected to central: ");
    Serial.println(central.address());
    digitalWrite(LED_BUILTIN, HIGH);
    resetActivityTimer();
    resetKeepAliveTimer();
    isConnected = true;
}

void onCentralDisconnected(BLEDevice central) {
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
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
            Serial.println("Connection or keep-alive timeout");
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
}
