#ifndef TIMING_H
#define TIMING_H

#include <Arduino.h>
#include "debug.h"

extern unsigned long lastHeartRateTime;
void resetActivityTimer();
void resetKeepAliveTimer();
void resetHeartRateTimer();
bool isConnectionTimedOut();
bool isKeepAliveTimedOut();
bool isHeartRateUpdateTime();

#endif // TIMING_H
