import 'package:flutter/material.dart';

class AdminHeaderBackground extends StatelessWidget {
  const AdminHeaderBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 45,
          color: const Color(0xFF002D62),
        ),
        Container(
          width: double.infinity,
          height: 13,
          color: const Color(0xFFCE1126),
        ),
      ],
    );
  }
}