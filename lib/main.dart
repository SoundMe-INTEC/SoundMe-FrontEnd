import 'package:flutter/material.dart';
import 'package:soundme_frontend/features/home/presentation/screens/home_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF002D62)),
        useMaterial3: true,
      ),

      home: const HomeScreen(),
    );
  }
}