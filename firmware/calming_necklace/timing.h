// timing.h

#ifndef TIMING_H
#define TIMING_H

#include <Arduino.h>

void resetActivityTimer();
void resetKeepAliveTimer();
bool isConnectionTimedOut();
bool isKeepAliveTimedOut();

#endif // TIMING_H