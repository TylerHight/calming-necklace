// settings.h
#ifndef SETTINGS_H
#define SETTINGS_H

#include <Arduino.h>
#include "debug.h"

// External variable declarations
extern unsigned long emission1Duration;
extern unsigned long releaseInterval1;
extern bool periodicEmissionEnabled;
extern byte heartrateThreshold;
extern bool heartRateBasedReleaseEnabled;
extern int highHeartRateThreshold;
extern int lowHeartRateThreshold;

// Function declarations
unsigned long getEmission1Duration();
unsigned long getInterval1();
bool getPeriodic1Enabled();
byte getHeartrateThreshold();
void handleSettingsUpdate();
void checkPeriodicEmissions();
void handleSwitchCommand(int command, int value);

// Settings handlers
void handleSettingsUpdate();
void checkPeriodicEmissions();
void setupPins();

#endif // SETTINGS_H
