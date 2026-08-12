import 'package:flutter/material.dart';

class AstroTheme {
  const AstroTheme._();

  static const _gold = Color(0xFFD9B65D);
  static const _navy = Color(0xFF0E1227);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          brightness: Brightness.dark,
          surface: const Color(0xFF171B32),
        ),
        scaffoldBackgroundColor: _navy,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF191E38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x246C76A7)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _navy,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _gold,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _gold),
        useMaterial3: true,
      );
}

