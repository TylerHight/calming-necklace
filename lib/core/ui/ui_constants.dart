import 'package:flutter/material.dart';

class UIConstants {
  // App Bar
  static const List<Color> appBarGradientColors = [
    Colors.white,
    Color(0xFF1976D2),  // Darker blue
  ];
  static const Color appBarTitleColor = Colors.white;
  static const Color appBarIconColor = Colors.white;
  static const double appBarElevation = 0.0;
  static const double appBarHeight = 56.0;
  static const EdgeInsets appBarPadding = EdgeInsets.symmetric(horizontal: 16.0);

  // Timed Toggle Button Shadows
  static const List<BoxShadow> timedToggleButtonShadows = [
    BoxShadow(
      color: Color(0x29000000),  // 16% opacity black
      blurRadius: 12.0,
      spreadRadius: 1.0,
      offset: Offset(0, 3),
    ),
  ];
  static const List<BoxShadow> timedToggleButtonPressedShadows = [
    BoxShadow(
      color: Color(0x40000000),  // 25% opacity black
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];

  // General
  static const Color floatingActionButtonColor = Colors.blueAccent; // Blue color for Floating Action Buttons
  
  // Settings Screen
  static const double settingsScreenHorizontalPadding = 16.0;
  static const double settingsScreenVerticalPadding = 24.0;
  static const double settingsCardElevation = 2.0;
  static const double settingsCardBorderRadius = 16.0;
  static const double settingsSectionSpacing = 16.0;
  static const double settingsTitleSize = 20.0;
  static const double settingsSubtitleSize = 16.0;

  // Note Card
  static const double noteCardContentTextSize = 18.0;
  static const double noteCardMetadataTextSize = 14.0;
  static const double noteCardPadding = 16.0;
  static const double noteCardMargin = 4.0;
  static const double noteCardDeviceTagPadding = 8.0;
  static const double noteCardDeviceTagVerticalPadding = 4.0;
  static const double noteCardDeviceTagBorderRadius = 12.0;
  static const double noteCardSpacing = 8.0;

  // Necklace Panel
  static const double necklacePanelPadding = 16.0;
  static const double necklacePanelElevation = 2.0;
  static const double necklacePanelBorderRadius = 20.0;
  static const Color necklacePanelBackgroundColor = Colors.white;
  static const Color greyShade200 = Color(0xFFEEEEEE);
  static const List<Color> necklacePanelGradientColors = [Colors.white, greyShade200];
  static const double necklacePanelBoxShadowBlurRadius = 8.0;
  static const Offset necklacePanelBoxShadowOffset = Offset(0, 4);
  static const Color necklacePanelBoxShadowColor = Colors.black;
  static const double titleTextSize = 24.0;
  static const double settingsIconSize = 29.0;
  static const double notesIconSize = 29.0;
  static const double settingsNotesSpacing = 0.0;
  static const double notesToggleSpacing = 14.0;
  static const double necklacePanelHeaderHorizontalPadding = 14.0;

  // Connection Status
  static const double connectionStatusTextSize = 14.0;
  static const FontWeight connectionStatusFontWeight = FontWeight.w500;
  static const double connectionStatusPaddingH = 10.0;
  static const double connectionStatusPaddingV = 4.0;
  static const double connectionStatusBorderRadius = 12.0;
  static const double connectionStatusDotSize = 6.0;
  static const double connectionStatusDotSpacing = 6.0;
  static const double connectionStatusSpacing = 8.0;

  // Periodic Emission Timer
  static const double periodicTimerSize = 120.0;
  static const double periodicTimerPadding = 16.0;
  static const double periodicTimerStrokeWidth = 8.0;
  static const double periodicTimerTimeTextSize = 20.0;
  static const double periodicTimerStatusTextSize = 12.0;
  static const double periodicTimerSpacing = 4.0;
  static const Color periodicTimerActiveColor = Colors.blue;
  static const Color periodicTimerPausedColor = Colors.orange;
  static const Color periodicTimerBackgroundColor = Color(0x332196F3);
  static const FontWeight periodicTimerTimeFontWeight = FontWeight.bold;
  static const Color periodicTimerStatusColor = Color(0xFF757575);

  // Timed Toggle Button
  static const double timedToggleButtonWidth = 160.0;  // Width of buttons
  static const double timedToggleButtonHeight = 55.0;
  static const double timedToggleButtonIconSize = 32.0;
  static const double timedToggleButtonSpacing = 12.0;  // Spacing between buttons
  static const double timedToggleButtonBorderRadius = 27.5;  // Half of height for perfect circle
  static const double timedToggleButtonBoxShadowBlurRadius = 12.0;
  static const Offset timedToggleButtonBoxShadowOffset = Offset(0, 2);
  static const double countdownTimerTextSize = 16.0;

  // Duration Picker
  static const double durationPickerHeight = 220.0;
  static const double durationPickerWidth = 280.0;
  static const double durationPickerItemExtent = 32.0;
  static const double durationPickerFontSize = 20.0;
  static const double durationPickerSpacing = 24.0;
  static const double durationPickerSeparatorWidth = 2.0;
  static const Color durationPickerSeparatorColor = Colors.grey;
  static const double durationPickerLabelSpacing = 8.0;
  static const double durationPickerDialogRadius = 20.0;
  static const double durationPickerButtonSpacing = 16.0;
  static const double durationPickerColumnWidth = 80.0;

  // Device Selector
  static const Color deviceSelectorBorderColor = Color(0xFFB0BEC5); // Darker border color
  static const Color deviceSelectorTextColor = Color(0xFF455A64); // Darker text color
  static const Color deviceSelectorIconColor = Color(0xFF455A64); // Darker icon color

  // Navigation Bar
  static const double navigationBarHeight = 60.0;
  static const double navigationBarElevation = 8.0;
  static const double navigationBarBorderRadius = 25.0;
  static const EdgeInsets navigationBarMargin = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  static const Color navigationBarSelectedColor = Color(0xFF1976D2);  // Blue
  static const Color navigationBarUnselectedColor = Color(0xFF9E9E9E);  // Grey
  static const double navigationBarSelectedIconSize = 28.0;
  static const double navigationBarUnselectedIconSize = 24.0;
  static const double navigationBarLabelFontSize = 12.0;
  static const FontWeight navigationBarLabelWeight = FontWeight.w500;
}
