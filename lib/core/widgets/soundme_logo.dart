import 'package:flutter/material.dart';

class SoundMeLogo extends StatelessWidget {
  const SoundMeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/soundme_logo.png',
          width: 315,
          height: 180,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'Traductor de Voz a Lengua de\nSeñas Dominicana',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF747474),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}