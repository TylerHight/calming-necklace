// timing.cpp

#include "timing.h"

static unsigned long lastActivityTime = 0;
static unsigned long lastKeepAliveTime = 0;
static const unsigned long DISCONNECT_TIMEOUT = 10000; // 10 seconds timeout
static const unsigned long KEEPALIVE_TIMEOUT = 120000;  // 2 minutes

void resetActivityTimer() {
    lastActivityTime = millis();
    Serial.println("Activity timer reset");
}

void resetKeepAliveTimer() {
    lastKeepAliveTime = millis();
}

bool isConnectionTimedOut() {
    return (millis() - lastActivityTime > DISCONNECT_TIMEOUT);
}

bool isKeepAliveTimedOut() {
    return (millis() - lastKeepAliveTime > KEEPALIVE_TIMEOUT);
}
