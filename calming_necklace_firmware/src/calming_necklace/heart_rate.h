// heart_rate.h
#ifndef HEART_RATE_H
#define HEART_RATE_H

#include <Arduino.h>
#include "debug.h"

// Heart rate simulation constants
#define MIN_HEART_RATE 60
#define MAX_HEART_RATE 100
#define OSCILLATION_PERIOD 30000  // Time for one complete oscillation (30 seconds)

// Variables for heart rate simulation
extern byte currentHeartRate;
extern unsigned long lastHeartRateUpdateTime;
extern bool heartRateBasedReleaseEnabled;
extern int highHeartRateThreshold;
extern int lowHeartRateThreshold;

// Function declarations
void initHeartRate();
void updateHeartRate();
byte getCurrentHeartRate();

#endif // HEART_RATE_H
