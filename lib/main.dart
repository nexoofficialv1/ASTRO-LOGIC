import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/client_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final clientStore = await ClientStore.open();
    runApp(AstroLogicApp(clientStore: clientStore));
  } catch (error) {
    runApp(_StartupFailureApp(message: error.toString()));
  }
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('ASTRO LOGIC could not open its offline database.\n$message'),
          ),
        ),
      ),
    );
  }
}
