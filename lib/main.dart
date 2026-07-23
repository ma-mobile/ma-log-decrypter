import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/decryptor_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color _primaryGreen = Color(0xFF0D530E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Log File Decryptor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryGreen,
          primary: _primaryGreen,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F8F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const DecryptorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
