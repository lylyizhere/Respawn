import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/igdb_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RespawnApp());
}

class RespawnApp extends StatelessWidget {
  const RespawnApp({super.key, this.service});

  final IgdbService? service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Respawn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
          primary: const Color(0xFF6C63FF),
        ),
      ),
      home: HomeScreen(service: service),
    );
  }
}
