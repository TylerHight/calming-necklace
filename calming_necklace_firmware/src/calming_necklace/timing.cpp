// timing.cpp

#include "timing.h"
#include "debug.h"

static unsigned long lastActivityTime = 0;
static unsigned long lastKeepAliveTime = 0;
unsigned long lastHeartRateTime = 0;
static const unsigned long DISCONNECT_TIMEOUT = 180000; // 3 minutes
static const unsigned long KEEPALIVE_TIMEOUT = 120000;  // 2 minutes
static const unsigned long HEARTRATE_UPDATE_INTERVAL = 5000; // Changed to 5 seconds as per requirements

void resetActivityTimer() {
    debugPrintln(DEBUG_TIMING, "Activity timer reset");
    lastActivityTime = millis();
}

void resetKeepAliveTimer() {
    debugPrintln(DEBUG_TIMING, "Keep-alive timer reset");
    lastKeepAliveTime = millis();
}

void resetHeartRateTimer() {
    debugPrintln(DEBUG_TIMING, "Heart rate timer reset");
    lastHeartRateTime = millis();
}

bool isConnectionTimedOut() {
    debugPrintf(DEBUG_TIMING, "Connection time elapsed: %lu ms\n", millis() - lastActivityTime);
    return (millis() - lastActivityTime > DISCONNECT_TIMEOUT);
}

bool isKeepAliveTimedOut() {
    return (millis() - lastKeepAliveTime > KEEPALIVE_TIMEOUT);
}

bool isHeartRateUpdateTime() {
    unsigned long currentTime = millis();

    debugPrintf(DEBUG_TIMING, "Current time: %lu ms\n", currentTime);
    debugPrintf(DEBUG_TIMING, "Last heart rate time: %lu ms\n", lastHeartRateTime);
    debugPrintf(DEBUG_TIMING, "Heart rate update interval: %lu ms\n", HEARTRATE_UPDATE_INTERVAL);

    return (abs(currentTime - lastHeartRateTime) >= HEARTRATE_UPDATE_INTERVAL);
}
