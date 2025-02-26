// heart_rate.cpp
#include "heart_rate.h"
#include <math.h>
#include "debug.h"
#include "led_control.h"

// Variables for heart rate simulation
byte currentHeartRate = MIN_HEART_RATE;
unsigned long lastHeartRateUpdateTime = 0;
static const unsigned long HEART_RATE_UPDATE_INTERVAL = 10000; // 10 seconds
extern bool heartRateBasedReleaseEnabled;
extern int highHeartRateThreshold;
extern int lowHeartRateThreshold;

void initHeartRate() {
    debugPrintln(DEBUG_HEART, "Initializing heart rate simulation");
    lastHeartRateUpdateTime = millis();
    currentHeartRate = MIN_HEART_RATE;
}

void updateHeartRate() {
    unsigned long currentTime = millis();

    // This creates a smooth transition between MIN and MAX heart rates
    float amplitude = (MAX_HEART_RATE - MIN_HEART_RATE) / 2.0;
    float offset = MIN_HEART_RATE + amplitude;
    float phase = (float)(currentTime % OSCILLATION_PERIOD) / OSCILLATION_PERIOD;

    // Calculate the heart rate using sine wave
    float sineValue = sin(2 * PI * phase);
    currentHeartRate = (byte)(offset + amplitude * sineValue);

    // Log the updated heart rate
    debugPrintf(DEBUG_HEART, "Heart rate: %d BPM\n", currentHeartRate);

    // Check if heart rate based release is enabled
    if (heartRateBasedReleaseEnabled) {
        // Trigger emission if heart rate is outside the threshold range
        if (currentHeartRate > highHeartRateThreshold || currentHeartRate < lowHeartRateThreshold) {
            debugPrintf(DEBUG_HEART, "Heart rate outside threshold range. Triggering emission.\n");
            // Call function to trigger emission based on heart rate
            triggerEmissionBasedOnHeartRate();
        }
    }

    // Update the last update time
    lastHeartRateUpdateTime = currentTime;

    // Log the last update time
    debugPrintf(DEBUG_HEART, "Last heart rate update time: %lu\n", lastHeartRateUpdateTime);
}

byte getCurrentHeartRate() {
    return currentHeartRate;
}

void triggerEmissionBasedOnHeartRate() {
    // Trigger the LED to turn on for the configured duration
    debugPrintln(DEBUG_HEART, "Triggering emission based on heart rate");
    // Turn on the LED
    handleLEDs(CMD_LED_RED);
    // The LED will be turned off after the emission duration by the main loop
}
