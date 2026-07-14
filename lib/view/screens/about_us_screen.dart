import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us screen')),
      body: Column(
        mainAxisAlignment: .center,
        children: [Text("Hola, About Us!")],
      ),
    );
  }
}
