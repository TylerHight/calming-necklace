// settings.cpp
#include "settings.h"
#include "ble_config.h"
#include "led_control.h"
#include "debug.h"

// Settings storage
static unsigned long emission1Duration = 10000;  // 10 seconds
static unsigned long interval1 = 300000;         // 5 minutes
static bool periodic1Enabled = false;
static byte heartrateThreshold = 90;            // Default 90 BPM
static bool heartRateBasedReleaseEnabled = false;
static int highHeartRateThreshold = 100;        // Default: 100 BPM
static int lowHeartRateThreshold = 60;          // Default: 60 BPM

// Timing variables for periodic emissions
static unsigned long lastEmission1Time = 0;

// Getters
unsigned long getEmission1Duration() { return emission1Duration; }
unsigned long getInterval1() { return interval1; }
bool getPeriodic1Enabled() { return periodic1Enabled; }
byte getHeartrateThreshold() { return heartrateThreshold; }

void handleSettingsUpdate() {
    if (emission1Characteristic.written()) {
        emission1Duration = emission1Characteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated emission1Duration: ");
        debugPrintf(DEBUG_SETTINGS, "%lu\n", emission1Duration);
    }

    if (interval1Characteristic.written()) {
        interval1 = interval1Characteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated interval1: ");
        debugPrintf(DEBUG_SETTINGS, "%lu\n", interval1);
    }

    if (periodic1Characteristic.written()) {
        periodic1Enabled = periodic1Characteristic.value();
        debugPrint(DEBUG_SETTINGS, "Updated periodic1Enabled: ");
        debugPrintf(DEBUG_SETTINGS, "%d\n", periodic1Enabled ? 1 : 0);
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

    if (periodic1Enabled && (currentTime - lastEmission1Time >= interval1)) {
        handleLEDs(CMD_LED_RED);
        delay(emission1Duration);
        handleLEDs(CMD_LED_OFF);
        lastEmission1Time = currentTime;
    }
}

void handleSwitchCommand(int command, int value) {
    switch (command) {
        case CMD_EMISSION1_DURATION:
            emission1Duration = value;
            break;
        case CMD_INTERVAL1:
            releaseInterval1 = value;
            break;
        case CMD_PERIODIC1:
            periodicEmissionEnabled = (value == 1);
            break;
        case CMD_HEART_RATE_ENABLED:
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