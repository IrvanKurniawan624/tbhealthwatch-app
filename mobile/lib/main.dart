import 'package:flutter/material.dart';
import 'presentation/tracing/tracing_map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0052CC)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const TracingMapPage(),
    );
  }
}
