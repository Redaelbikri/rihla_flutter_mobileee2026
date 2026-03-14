import 'package:flutter/material.dart';

class AppGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDE9D8),
      Color(0xFFF7D8C3),
      Color(0xFFECC7B5),
    ],
  );

  static const glass = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xCCFFFFFF),
      Color(0x99FFFFFF),
    ],
  );
}
