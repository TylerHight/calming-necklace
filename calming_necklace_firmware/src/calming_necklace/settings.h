// settings.h
#ifndef SETTINGS_H
#define SETTINGS_H

#include <Arduino.h>
#include "debug.h"

// External variable declarations
extern int emission1Duration;
extern int releaseInterval1;
extern bool periodicEmissionEnabled;
extern bool heartRateBasedReleaseEnabled;
extern int highHeartRateThreshold;
extern int lowHeartRateThreshold;

// Settings getters
unsigned long getEmission1Duration();
unsigned long getEmission2Duration();
unsigned long getInterval1();
unsigned long getInterval2();
bool getPeriodic1Enabled();
bool getPeriodic2Enabled();
byte getHeartrateThreshold();

// Settings handlers
void handleSettingsUpdate();
void checkPeriodicEmissions();
void setupPins();
void handlePeripheralLoop(BLEDevice central);

#endif // SETTINGS_H