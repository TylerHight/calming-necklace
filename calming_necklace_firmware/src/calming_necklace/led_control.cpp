// led_control.cpp
#include "led_control.h"
#include "debug.h"

void setupPins() {
    pinMode(LEDR, OUTPUT);
    pinMode(LEDG, OUTPUT);
    pinMode(LEDB, OUTPUT);
    pinMode(LED_BUILTIN, OUTPUT);

    digitalWrite(LED_BUILTIN, LOW);
    digitalWrite(LEDR, HIGH);
    digitalWrite(LEDG, HIGH);
    digitalWrite(LEDB, HIGH);
}

void handleLEDs(byte command) {
    debugPrint(DEBUG_LED, "\nHandling LED command: ");
    debugPrintf(DEBUG_LED, "%d\n", command);

    switch (command) {
        case CMD_LED_ON:
            debugPrintln(DEBUG_LED, "Red LED on");
            digitalWrite(LEDR, LOW);
            digitalWrite(LEDG, HIGH);
            digitalWrite(LEDB, HIGH);
            break;
        case CMD_LED_OFF:
            debugPrintln(DEBUG_LED, "LEDs off");
            digitalWrite(LEDR, HIGH);
            digitalWrite(LEDG, HIGH);
            digitalWrite(LEDB, HIGH);
            break;
        default:
            debugPrintln(DEBUG_LED, "Ignoring unsupported LED command");
            break;
    }
}