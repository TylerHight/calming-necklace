# Calming Necklace Firmware

This firmware is designed for the Arduino Nano 33 BLE and controls a calming necklace with various features such as heart rate monitoring, autonomous fan control, BLE synchronization with an app, and periodic emissions.

## Features

### Heart Rate Sensor Integration
- **Firmware**: Implement BLE Central logic to connect to a heart rate sensor.
- **Test**: Use nRF Connect to mock heart rate data.

### Autonomous Fan Control
- **Firmware**: Code threshold checks and fan timer.
- **Test**: Verify that the fan turns on/off autonomously without the app.

### App-Necklace BLE Sync
- **Firmware**: Define `SETTINGS_CHAR` and EEPROM storage.
- **App**: Add a settings screen with write/confirm logic.

### Periodic Emissions
- **Firmware**: Implement a scheduler using `millis()`.

### Contingency & Final Prep
- Add a factory test mode (fan/LED blink on startup).
- Write a factory test script and pinout diagram.

## File Structure

- `calming_necklace.ino`: Main firmware file.
- `ble_config.h` / `ble_config.cpp`: BLE configuration and handling.
- `led_control.h` / `led_control.cpp`: LED control functions.
- `settings.h` / `settings.cpp`: Settings management.
- `timing.h` / `timing.cpp`: Timing functions.

## Setup

1. **Hardware**: Connect the Arduino Nano 33 BLE to the calming necklace hardware.
2. **Software**: Install the Arduino IDE and required libraries.
3. **Upload**: Compile and upload the firmware to the Arduino Nano 33 BLE.

## Usage

1. **Heart Rate Monitoring**: The necklace will connect to a heart rate sensor and adjust its behavior based on the received data.
2. **Autonomous Fan Control**: The fan will turn on/off based on predefined thresholds.
3. **BLE Sync**: Use the app to sync settings with the necklace.
4. **Periodic Emissions**: The necklace will perform periodic emissions based on the scheduler.

## Testing

- Use nRF Connect to mock heart rate data and verify BLE functionality.
- Verify autonomous fan control by checking the fan's response to threshold conditions.
- Sync settings using the app and confirm the changes on the necklace.
- Ensure periodic emissions occur as scheduled.

## Factory Test Mode

- On startup, the fan and LEDs will blink to indicate factory test mode.
- A factory test script and pinout diagram will be provided for testing and verification.

## Pinout Diagram

(Include a detailed pinout diagram here)

## License

(Include license information here)

## Contact

For any questions or support, please contact: 
- Tyler Hight
- Email: highttyler@gmail.com