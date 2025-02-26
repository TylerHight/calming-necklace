// heart_rate.cpp
#include "heart_rate.h"
#include <math.h>
#include "debug.h"

// Variables for heart rate simulation
byte currentHeartRate = MIN_HEART_RATE;
unsigned long lastHeartRateUpdateTime = 0;
static const unsigned long HEART_RATE_UPDATE_INTERVAL = 10000; // 10 seconds

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

    // Update the last update time
    lastHeartRateUpdateTime = currentTime;

    // Log the last update time
    debugPrintf(DEBUG_HEART, "Last heart rate update time: %d \n", lastHeartRateUpdateTime);

    // Log the updated heart rate
    debugPrintf(DEBUG_HEART, "Heart rate: %d BPM\n", currentHeartRate);
}

byte getCurrentHeartRate() {
    return currentHeartRate;
}
