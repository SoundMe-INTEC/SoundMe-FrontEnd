import 'package:flutter/material.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('translate screen')),
      body: Column(
        mainAxisAlignment: .center,
        children: [Text("Hola, Translate!")],
      ),
    );
  }
}
