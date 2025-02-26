// debug.h
#ifndef DEBUG_H
#define DEBUG_H

#include <Arduino.h>

// Debug categories
#define DEBUG_GENERAL   0x01
#define DEBUG_HEART     0x02
#define DEBUG_BLE       0x04
#define DEBUG_LED       0x08
#define DEBUG_SETTINGS  0x10
#define DEBUG_TIMING    0x20
#define DEBUG_ALL       0xFF

// Initialize debug system
void debugInit();

// Set debug flags
void debugEnable(uint8_t categories);
void debugDisable(uint8_t categories);

// Debug print functions
void debugPrint(uint8_t category, const char* message);
void debugPrintln(uint8_t category, const char* message);
void debugPrintf(uint8_t category, const char* format, ...);

// Check if debug is enabled for a category
bool isDebugEnabled(uint8_t category);

// Global debug enable/disable
extern bool globalDebugEnabled;

// Category flags
extern uint8_t debugCategories;

#endif // DEBUG_H
