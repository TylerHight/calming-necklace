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
bool heartRateBasedReleaseEnabled = false;
int highHeartRateThreshold = 100;        // Default: 100 BPM
int lowHeartRateThreshold = 60;          // Default: 60 BPM

// Timing variables for periodic emissions
static unsigned long lastEmission1Time = 0;

// Getters
unsigned long getEmission1Duration() {
    return emission1Duration;
}

unsigned long getInterval1() {
    return releaseInterval1;
}

bool getPeriodic1Enabled() {
    return periodicEmissionEnabled;
}

bool getHeartRateBasedReleaseEnabled() {
    return heartRateBasedReleaseEnabled;
}

int getHighHeartRateThreshold() {
    return highHeartRateThreshold;
}

int getLowHeartRateThreshold() {
    return lowHeartRateThreshold;
}

void handleSettingsUpdate() {
    if (emission1Characteristic.written()) {
        emission1Duration = emission1Characteristic.value() * 1000; // Convert seconds to milliseconds
        debugPrintf(DEBUG_SETTINGS, "Emission duration updated: %lu ms\n", emission1Duration);
    }

    if (interval1Characteristic.written()) {
        releaseInterval1 = interval1Characteristic.value() * 1000; // Convert seconds to milliseconds
        debugPrintf(DEBUG_SETTINGS, "Release interval updated: %lu ms\n", releaseInterval1);
    }

    if (periodic1Characteristic.written()) {
        periodicEmissionEnabled = (periodic1Characteristic.value() == 1);
        debugPrintf(DEBUG_SETTINGS, "Periodic emission %s\n", periodicEmissionEnabled ? "enabled" : "disabled");
    }

    if (heartRateEnabledCharacteristic.written()) {
        heartRateBasedReleaseEnabled = (heartRateEnabledCharacteristic.value() == 1);
        debugPrintf(DEBUG_SETTINGS, "Heart rate based release %s\n", heartRateBasedReleaseEnabled ? "enabled" : "disabled");
    }

    if (highHeartRateThresholdCharacteristic.written()) {
        highHeartRateThreshold = highHeartRateThresholdCharacteristic.value();
        debugPrintf(DEBUG_SETTINGS, "High heart rate threshold updated: %d BPM\n", highHeartRateThreshold);
    }

    if (lowHeartRateThresholdCharacteristic.written()) {
        lowHeartRateThreshold = lowHeartRateThresholdCharacteristic.value();
        debugPrintf(DEBUG_SETTINGS, "Low heart rate threshold updated: %d BPM\n", lowHeartRateThreshold);
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
