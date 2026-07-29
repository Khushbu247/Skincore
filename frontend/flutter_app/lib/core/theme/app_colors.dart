import 'package:flutter/material.dart';

/// Brand tokens — kept in sync with the design used in the clickable
/// prototype (purple → rose → coral gradient, warm off-white background).
class AppColors {
  AppColors._();

  static const plum = Color(0xFF3C1E4A);
  static const purple = Color(0xFF7A3B93);
  static const rose = Color(0xFFE9497A);
  static const coral = Color(0xFFF4915E);
  static const gold = Color(0xFFF7B955);

  static const ink = Color(0xFF251A2E);
  static const muted = Color(0xFF8C7F96);
  static const mutedLight = Color(0xFFB8AFC0);

  static const bgLight = Color(0xFFFBF7F9);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const lineLight = Color(0xFFEFE7F0);

  static const bgDark = Color(0xFF17121C);
  static const surfaceDark = Color(0xFF221A2A);
  static const lineDark = Color(0xFF322A3A);

  static const success = Color(0xFF3FA772);
  static const warning = Color(0xFFB5730F);
  static const danger = Color(0xFFC13B4A);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, rose, coral],
  );
}
