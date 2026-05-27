import 'package:flutter/material.dart';
import 'package:soaksafe/core/theme/soaksafe_colors.dart';

ThemeData buildSoakSafeTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SoakSafeColors.homePrimary,
      primary: SoakSafeColors.homePrimary,
      onPrimary: Colors.white,
      surface: SoakSafeColors.frostedSurface,
      onSurface: SoakSafeColors.homeFormOnSurface,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: SoakSafeColors.homeFormOnSurfaceVariant),
    ),
  );
}
