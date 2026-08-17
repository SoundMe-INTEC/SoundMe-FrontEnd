import 'package:flutter/material.dart';

class HeaderBackground extends StatelessWidget {
  const HeaderBackground({super.key});

  static const Color primaryNavy = Color(0xFF002D62);
  static const Color accentRed = Color(0xFFCE1126);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -140,
      left: -100,
      right: -100,
      child: Transform.rotate(
        angle: -0.28, // Inclinación equivalente a Figma
        child: Column(
          children: [
            Container(
              height: 230,
              color: primaryNavy,
            ),
            Container(
              height: 25,
              color: accentRed,
            ),
          ],
        ),
      ),
    );
  }
}