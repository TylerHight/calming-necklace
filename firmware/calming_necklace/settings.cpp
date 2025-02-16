// settings.cpp
#include "settings.h"
#include "ble_config.h"
#include "led_control.h"

// Settings storage
static unsigned long emission1Duration = 10000;  // 10 seconds
static unsigned long interval1 = 300000;         // 5 minutes
static bool periodic1Enabled = false;
static byte heartrateThreshold = 90;            // Default 90 BPM

// Timing variables for periodic emissions
static unsigned long lastEmission1Time = 0;

// Getters
unsigned long getEmission1Duration() { return emission1Duration; }
unsigned long getInterval1() { return interval1; }
bool getPeriodic1Enabled() { return periodic1Enabled; }
byte getHeartrateThreshold() { return heartrateThreshold; }

void handleSettingsUpdate() {
    if (emission1Characteristic.written()) {
        emission1Duration = emission1Characteristic.value();
        Serial.print("Updated emission1Duration: ");
        Serial.println(emission1Duration);
    }

    if (interval1Characteristic.written()) {
        interval1 = interval1Characteristic.value();
        Serial.print("Updated interval1: ");
        Serial.println(interval1);
    }

    if (periodic1Characteristic.written()) {
        periodic1Enabled = periodic1Characteristic.value();
        Serial.print("Updated periodic1Enabled: ");
        Serial.println(periodic1Enabled);
    }

    if (heartrateCharacteristic.written()) {
        heartrateThreshold = heartrateCharacteristic.value();
        Serial.print("Updated heartrateThreshold: ");
        Serial.println(heartrateThreshold);
    }
}

void checkPeriodicEmissions() {
    unsigned long currentTime = millis();

    if (periodic1Enabled && (currentTime - lastEmission1Time >= interval1)) {
        handleLEDs(CMD_LED_RED);
        delay(emission1Duration);
        handleLEDs(CMD_LED_OFF);
        lastEmission1Time = currentTime;
    }
}