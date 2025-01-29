import 'package:flutter/material.dart';

class UIConstants {
  // General
  static const Color fabColor = Colors.blueAccent; // Blue color for FABs

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
  static const double popoutMenuIconSize = 30.0;
  
  // Timed Toggle Button
  static const double timedToggleButtonWidth = 120.0;  // Width of buttons
  static const double timedToggleButtonHeight = 55.0;
  static const double timedToggleButtonIconSize = 32.0;
  static const double timedToggleButtonSpacing = 12.0;  // Spacing between buttons
  static const double timedToggleButtonBorderRadius = 30.0;
  static const double timedToggleButtonBoxShadowBlurRadius = 8.0;
  static const Offset timedToggleButtonBoxShadowOffset = Offset(0, 2);
  static const double countdownTimerTextSize = 16.0;
}
