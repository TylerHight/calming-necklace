// settings.h
#ifndef SETTINGS_H
#define SETTINGS_H

#include <Arduino.h>
#include "debug.h"

// Settings variables
extern unsigned long emission1Duration;
extern unsigned long releaseInterval1;
extern bool periodicEmissionEnabled;
extern bool heartRateBasedReleaseEnabled;
extern int highHeartRateThreshold;
extern int lowHeartRateThreshold;

// Function declarations
void handleSettingsUpdate();
unsigned long getEmission1Duration();
unsigned long getInterval1();
bool getPeriodic1Enabled();
bool getHeartRateBasedReleaseEnabled();
int getHighHeartRateThreshold();
int getLowHeartRateThreshold();

// Settings handlers
void handleSettingsUpdate();
void checkPeriodicEmissions();
void setupPins();

#endif // SETTINGS_H
