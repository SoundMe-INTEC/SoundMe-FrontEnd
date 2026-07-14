import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('settings screen')),
      body: Column(
        mainAxisAlignment: .center,
        children: [Text("Hola, Settings!")],
      ),
    );
  }
}
