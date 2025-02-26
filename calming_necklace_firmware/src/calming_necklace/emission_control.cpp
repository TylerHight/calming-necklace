// emission_control.cpp
#include "emission_control.h"

// Emission state variables
static byte emissionState = EMISSION_IDLE;
static unsigned long emissionStartTime = 0;
static unsigned long lastEmissionTime = 0;
static byte lastTriggerSource = 0;
static bool heartRateHighTriggered = false;
static bool heartRateLowTriggered = false;

void setupEmissionControl() {
    debugPrintln(DEBUG_GENERAL, "Initializing emission control system");
    emissionState = EMISSION_IDLE;
    emissionStartTime = 0;
    lastEmissionTime = 0;
    lastTriggerSource = 0;
}

void updateEmissionState() {
    unsigned long currentTime = millis();
    
    // Check if an active emission should be stopped
    if (emissionState == EMISSION_ACTIVE) {
        if (currentTime - emissionStartTime >= emission1Duration) {
            debugPrintln(DEBUG_GENERAL, "Emission complete, turning off");
            handleLEDs(CMD_LED_OFF);
            emissionState = EMISSION_IDLE;
        }
    }
    
    // Check for periodic emissions if enabled
    if (periodicEmissionEnabled && emissionState == EMISSION_IDLE) {
        if (currentTime - lastEmissionTime >= releaseInterval1) {
            triggerEmission(TRIGGER_PERIODIC);
        }
    }
}

bool triggerEmission(byte triggerSource) {
    // Don't trigger a new emission if one is already active
    if (emissionState == EMISSION_ACTIVE) {
        debugPrintln(DEBUG_GENERAL, "Emission already active, ignoring trigger");
        return false;
    }
    
    debugPrint(DEBUG_GENERAL, "Triggering emission from source: ");
    debugPrintf(DEBUG_GENERAL, "%d\n", triggerSource);
    
    // Start the emission
    emissionState = EMISSION_ACTIVE;
    emissionStartTime = millis();
    lastEmissionTime = emissionStartTime;
    lastTriggerSource = triggerSource;
    
    // Turn on the LED (representing the fan)
    handleLEDs(CMD_LED_RED);
    
    return true;
}

bool isEmissionActive() {
    return (emissionState == EMISSION_ACTIVE);
}

void stopEmission() {
    if (emissionState == EMISSION_ACTIVE) {
        handleLEDs(CMD_LED_OFF);
        emissionState = EMISSION_IDLE;
        debugPrintln(DEBUG_GENERAL, "Emission manually stopped");
    }
}

void checkHeartRateBasedEmission(byte currentHeartRate) {
    if (!heartRateBasedReleaseEnabled || emissionState == EMISSION_ACTIVE) {
        return;
    }
    
    // Check for high heart rate threshold crossing
    if (currentHeartRate > highHeartRateThreshold && !heartRateHighTriggered) {
        debugPrint(DEBUG_GENERAL, "Heart rate above threshold: ");
        debugPrintf(DEBUG_GENERAL, "%d > %d\n", currentHeartRate, highHeartRateThreshold);
        heartRateHighTriggered = true;
        triggerEmission(TRIGGER_HEART_RATE);
    } else if (currentHeartRate <= highHeartRateThreshold) {
        heartRateHighTriggered = false;
    }
    
    // Check for low heart rate threshold crossing
    if (currentHeartRate < lowHeartRateThreshold && !heartRateLowTriggered) {
        debugPrint(DEBUG_GENERAL, "Heart rate below threshold: ");
        debugPrintf(DEBUG_GENERAL, "%d < %d\n", currentHeartRate, lowHeartRateThreshold);
        heartRateLowTriggered = true;
        triggerEmission(TRIGGER_HEART_RATE);
    } else if (currentHeartRate >= lowHeartRateThreshold) {
        heartRateLowTriggered = false;
    }
}

unsigned long getLastEmissionTime() {
    return lastEmissionTime;
}

byte getEmissionState() {
    return emissionState;
}

byte getLastTriggerSource() {
    return lastTriggerSource;
}
