import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_screen.dart';
import 'services/mqtt_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MqttService()..connect(),
      child: const CultivoApp(),
    ),
  );
}

class CultivoApp extends StatelessWidget {
  const CultivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),

        cardColor: const Color(0xFF1C1F26),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFEAEAEA)),
          bodySmall: TextStyle(color: Color(0xFFA0A0A0)),
          titleMedium: TextStyle(
            color: Color(0xFFEAEAEA),
            fontWeight: FontWeight.w600,
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1115),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey.shade800,
          selectedColor: Colors.green,
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}