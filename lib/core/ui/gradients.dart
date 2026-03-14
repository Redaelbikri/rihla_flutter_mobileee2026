import 'package:flutter/material.dart';

class AppGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF2D9),
      Color(0xFFF7D3A5),
      Color(0xFFEAA06B),
      Color(0xFFCC6B49),
    ],
    stops: [0.0, 0.34, 0.72, 1.0],
  );

  static const glass = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xE6FFFFFF),
      Color(0xB3FFFFFF),
    ],
  );

  static const oasis = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D5C63),
      Color(0xFF197278),
      Color(0xFF2A9D8F),
    ],
  );

  static const sunsetOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00FFFFFF),
      Color(0x99391D18),
      Color(0xCC1C1614),
    ],
  );
}
