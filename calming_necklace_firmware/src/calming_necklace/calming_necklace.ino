#include <ArduinoBLE.h>
#include "ble_config.h"
#include "led_control.h"
#include "settings.h"
#include "timing.h"
#include "heart_rate.h"
#include "debug.h"
#include "emission_control.h"

void setup() {
    Serial.begin(9600);
    debugInit();
    debugPrintln(DEBUG_GENERAL, "\n=== Calming Necklace Startup ===");

    setupPins();
    setupEmissionControl();
    initHeartRate();

    if (!setupBLE()) {
        // Continue with limited functionality if BLE fails
        debugPrintln(DEBUG_GENERAL, "Operating in limited mode without BLE");
    }

    resetHeartRateTimer();
    debugPrintln(DEBUG_GENERAL, "\nDevice Ready!");
    debugPrintln(DEBUG_GENERAL, "=== Setup Complete ===\n");
}

void loop() {
    BLEDevice central = BLE.central();
    
    if (isHeartRateUpdateTime()) {
        updateHeartRate();
        heartrateCharacteristic.writeValue(getCurrentHeartRate());
        //Serial.print("Heart rate: "); Serial.print(getCurrentHeartRate()); Serial.println(" BPM");
    }

    updateEmissionState();
    if (central) {
        onCentralConnected(central);

        while (central.connected()) {
            handlePeripheralLoop(central);
        }

        onCentralDisconnected(central);
    }
}
