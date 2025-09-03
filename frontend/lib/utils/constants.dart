import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color.fromARGB(255, 38, 148, 238);
  static const Color secondaryBlue = Color.fromARGB(255, 126, 159, 186);
  static const Color lightBlue = Color.fromARGB(255, 182, 210, 233);
  static const Color darkText = Color.fromARGB(255, 0, 2, 3);
  static const Color white = Color.fromARGB(255, 255, 255, 255);
}

class AppStyles {
  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'consolas',
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontFamily: 'consolas',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.secondaryBlue,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16,
    color: AppColors.darkText,
  );
}

class AppSizes {
  static const double buttonHeight = 50.0;
  static const double moodButtonSize = 60.0;
  static const double iconSize = 30.0;
  static const double spacing = 16.0;
  static const double largeSpacing = 32.0;
}

class AppConstants {
  static const String apiBaseUrl = 'http://192.168.0.111:8080';
} 