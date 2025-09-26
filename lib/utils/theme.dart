
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF0F2F5),
    fontFamily: 'Exo2',
    primaryColor: Colors.blue,
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.light)
        .copyWith(secondary: Colors.blueAccent),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1c1c1e),
    fontFamily: 'Exo2',
    primaryColor: Colors.cyan,
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark)
        .copyWith(secondary: Colors.cyanAccent),
  );
}
