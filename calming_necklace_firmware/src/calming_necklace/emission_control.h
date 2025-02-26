// emission_control.h
#ifndef EMISSION_CONTROL_H
#define EMISSION_CONTROL_H

#include <Arduino.h>
#include "debug.h"
#include "led_control.h"
#include "settings.h"

// Emission states
#define EMISSION_IDLE 0
#define EMISSION_ACTIVE 1

// Emission trigger sources
#define TRIGGER_MANUAL 1
#define TRIGGER_PERIODIC 2
#define TRIGGER_HEART_RATE 3

// Function declarations
void setupEmissionControl();
void updateEmissionState();
bool triggerEmission(byte triggerSource);
bool isEmissionActive();
void stopEmission();
void checkHeartRateBasedEmission(byte currentHeartRate);
unsigned long getLastEmissionTime();
byte getEmissionState();
byte getLastTriggerSource();

#endif // EMISSION_CONTROL_H
