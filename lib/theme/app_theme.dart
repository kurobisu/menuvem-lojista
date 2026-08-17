import 'package:flutter/material.dart';

// ── Menuvem Brand Colors ────────────────────────────────────────────────

const purplePrimary = Color(0xFF6B21A8);
const purpleLight = Color(0xFF9333EA);
const purpleDark = Color(0xFF4C1D95);
const purpleContainer = Color(0xFFE9D5FF);
const purpleOnContainer = Color(0xFF3B0764);

const yellowSecondary = Color(0xFFD97706);
const yellowContainer = Color(0xFFFEF3C7);
const yellowOnContainer = Color(0xFF78350F);

const backgroundLight = Color(0xFFFAFAFA);
const surfaceLight = Color(0xFFFFFFFF);
const surfaceVariantLight = Color(0xFFF3F0F7);
const outlineLight = Color(0xFFCABDD8);
const onBackgroundLight = Color(0xFF1C1C1E);
const onSurfaceVariantLight = Color(0xFF5C4F6E);

const successGreen = Color(0xFF15803D);
const successContainer = Color(0xFFDCFCE7);
const errorRed = Color(0xFFDC2626);
const errorContainer = Color(0xFFFEE2E2);
const warningOrange = Color(0xFFEA580C);
const warningContainer = Color(0xFFFFEDD5);

const trendUp = Color(0xFFDC2626);
const trendStable = Color(0xFF6B7280);
const trendDown = Color(0xFF15803D);

ThemeData menuvemLojistaTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: purplePrimary,
    brightness: Brightness.light,
  ).copyWith(
    primary: purplePrimary,
    onPrimary: Colors.white,
    primaryContainer: purpleContainer,
    onPrimaryContainer: purpleOnContainer,
    secondary: yellowSecondary,
    secondaryContainer: yellowContainer,
    onSecondaryContainer: yellowOnContainer,
    surface: surfaceLight,
    surfaceContainerHighest: surfaceVariantLight,
    onSurfaceVariant: onSurfaceVariantLight,
    outline: outlineLight,
    error: errorRed,
    errorContainer: errorContainer,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundLight,
      foregroundColor: onBackgroundLight,
      elevation: 0,
    ),
  );
}
