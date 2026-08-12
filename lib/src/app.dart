import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_copy.dart';
import 'data/client_store.dart';
import 'screens/dashboard_screen.dart';
import 'theme/astro_theme.dart';

class AstroLogicApp extends StatefulWidget {
  const AstroLogicApp({required this.clientStore, super.key});

  final ClientStore clientStore;

  @override
  State<AstroLogicApp> createState() => _AstroLogicAppState();
}

class _AstroLogicAppState extends State<AstroLogicApp> {
  Locale _locale = const Locale('bn');

  void _toggleLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'bn'
          ? const Locale('en')
          : const Locale('bn');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ASTRO LOGIC',
      locale: _locale,
      supportedLocales: AppCopy.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AstroTheme.light,
      darkTheme: AstroTheme.dark,
      themeMode: ThemeMode.dark,
      home: DashboardScreen(
        clientStore: widget.clientStore,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}
