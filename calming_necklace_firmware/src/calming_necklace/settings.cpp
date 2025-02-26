// settings.cpp
#include "settings.h"
#include "ble_config.h"
#include "led_control.h"
#include "emission_control.h"
#include "debug.h"

// Settings storage
unsigned long emission1Duration = 10000;  // 10 seconds
unsigned long releaseInterval1 = 30000;  // 30 seconds
bool periodicEmissionEnabled = false;
byte heartrateThreshold = 90;            // Default 90 BPM
bool heartRateBasedReleaseEnabled = false;
int highHeartRateThreshold = 100;        // Default: 100 BPM
int lowHeartRateThreshold = 60;          // Default: 60 BPM

// Timing variables for periodic emissions
static unsigned long lastEmission1Time = 0;

// Getters
unsigned long getEmission1Duration() { return emission1Duration; }
unsigned long getInterval1() { return releaseInterval1; }
bool getPeriodic1Enabled() { return periodicEmissionEnabled; }
byte getHeartrateThreshold() { return heartrateThreshold; }

void handleSettingsUpdate() {
    if (emission1Characteristic.written()) {
        emission1Duration = emission1Characteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated emission1Duration: ");
        debugPrintf(DEBUG_SETTINGS, "%lu\n", emission1Duration);
    }

    if (interval1Characteristic.written()) {
        releaseInterval1 = interval1Characteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated interval1: ");
        debugPrintf(DEBUG_SETTINGS, "%lu\n", releaseInterval1);
    }

    if (periodic1Characteristic.written()) {
        periodicEmissionEnabled = periodic1Characteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated periodic1Enabled: ");
        debugPrintf(DEBUG_SETTINGS, "%d\n", periodicEmissionEnabled ? 1 : 0);
    }

    if (heartrateCharacteristic.written()) {
        heartrateThreshold = heartrateCharacteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated heartrateThreshold: ");
        debugPrintf(DEBUG_SETTINGS, "%d\n", heartrateThreshold);
    }

    if (heartRateEnabledCharacteristic.written()) {
        heartRateBasedReleaseEnabled = heartRateEnabledCharacteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated heartRateBasedReleaseEnabled: ");
        debugPrintf(DEBUG_SETTINGS, "%d\n", heartRateBasedReleaseEnabled ? 1 : 0);
    }

    if (highHeartRateThresholdCharacteristic.written()) {
        highHeartRateThreshold = highHeartRateThresholdCharacteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated highHeartRateThreshold: ");
        debugPrintf(DEBUG_SETTINGS, "%d\n", highHeartRateThreshold);
    }

    if (lowHeartRateThresholdCharacteristic.written()) {
        lowHeartRateThreshold = lowHeartRateThresholdCharacteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated lowHeartRateThreshold: ");
        debugPrintf(DEBUG_SETTINGS, "%d\n", lowHeartRateThreshold);
    }
}

void checkPeriodicEmissions() {
    unsigned long currentTime = millis();

    if (periodicEmissionEnabled && (currentTime - lastEmission1Time >= releaseInterval1)) {
        triggerEmission(TRIGGER_PERIODIC);
    }
}

void handleSwitchCommand(int command, int value) {
    switch (command) {
        case 4: // CMD_EMISSION1_DURATION
            emission1Duration = value;
            break;
        case 6: // CMD_INTERVAL1
            releaseInterval1 = value;
            break;
        case 8: // CMD_PERIODIC1
            periodicEmissionEnabled = (value == 1);
            break;
        case 10: // CMD_HEART_RATE_ENABLED
            heartRateBasedReleaseEnabled = (value == 1);
            break;
        case CMD_HIGH_HEART_RATE_THRESHOLD:
            highHeartRateThreshold = value;
            break;
        case CMD_LOW_HEART_RATE_THRESHOLD:
            lowHeartRateThreshold = value;
            break;
    }
}
