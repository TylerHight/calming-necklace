#ifndef LED_CONTROL_H
#define LED_CONTROL_H

#include <Arduino.h>
#include "debug.h"
#include "ble_config.h"

void setupPins();
void handleLEDs(byte command);

#endif // LED_CONTROL_H