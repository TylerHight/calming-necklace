// debug.cpp
#include "debug.h"
#include <stdarg.h>

// Debug control variables
bool globalDebugEnabled = true;
uint8_t debugCategories = DEBUG_GENERAL | DEBUG_BLE;

void debugInit() {
  // Initialize serial if not already done
  if (!Serial) {
    Serial.begin(9600);
    delay(100); // Short delay to ensure serial is ready
  }
  
  debugPrintln(DEBUG_GENERAL, "Debug system initialized");
}

void debugEnable(uint8_t categories) {
  debugCategories |= categories;
  debugPrintf(DEBUG_GENERAL, "Debug enabled for categories: 0x%02X", categories);
}

void debugDisable(uint8_t categories) {
  debugCategories &= ~categories;
  debugPrintf(DEBUG_GENERAL, "Debug disabled for categories: 0x%02X", categories);
}

bool isDebugEnabled(uint8_t category) {
  return globalDebugEnabled && (debugCategories & category);
}

void debugPrint(uint8_t category, const char* message) {
  if (isDebugEnabled(category)) {
    Serial.print(message);
  }
}

void debugPrintln(uint8_t category, const char* message) {
  if (isDebugEnabled(category)) {
    Serial.println(message);
  }
}

void debugPrintf(uint8_t category, const char* format, ...) {
  if (isDebugEnabled(category)) {
    char buffer[128]; // Buffer for formatted string
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    Serial.print(buffer);
  }
}
