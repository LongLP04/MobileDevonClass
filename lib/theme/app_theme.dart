import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color darkBackground = Color(0xFF110C32);
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF211C4A), Color(0xFF0B0824)],
  );

  static TextStyle get screenTitle => const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyText => TextStyle(
        color: Colors.white.withOpacity(0.85),
        fontSize: 16,
      );

  static InputDecoration inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.lightBlueAccent),
      ),
    );
  }

  static ButtonStyle primaryButtonStyle = FilledButton.styleFrom(
    backgroundColor: const Color(0xFF5ED3E4),
    foregroundColor: darkBackground,
    padding: const EdgeInsets.symmetric(vertical: 16),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: BorderSide(color: Colors.white.withOpacity(0.4)),
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  static const BoxDecoration gradientBackground = BoxDecoration(
    gradient: backgroundGradient,
  );
}
