import 'package:flutter/material.dart';

class UIConstants {
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
  
  // Action buttons and status indicators
  static const double actionButtonIconSize = 24.0;
  static const double connectionStatusTextSize = 14.0;
  static const FontWeight connectionStatusFontWeight = FontWeight.w500;

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
  static const double settingsIconSize = 30.0;
  static const double notesIconSize = 30.0;
  static const double settingsNotesSpacing = 0.0;
  static const double notesToggleSpacing = 14.0;

  // Connection Status
  static const double connectionStatusPaddingH = 8.0;
  static const double connectionStatusPaddingV = 4.0;
  static const double connectionStatusBorderRadius = 12.0;
  static const double connectionStatusDotSize = 6.0;
  static const double connectionStatusDotSpacing = 6.0;
  static const double connectionStatusSpacing = 8.0;

  // Timed Toggle Button
  static const double timedToggleButtonWidth = 160.0;  // Width of buttons
  static const double timedToggleButtonHeight = 55.0;
  static const double timedToggleButtonIconSize = 32.0;
  static const double timedToggleButtonSpacing = 12.0;  // Spacing between buttons
  static const double timedToggleButtonBorderRadius = 30.0;
  static const double timedToggleButtonBoxShadowBlurRadius = 8.0;
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
}
