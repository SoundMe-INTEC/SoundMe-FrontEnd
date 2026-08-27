import 'package:flutter/material.dart';

class AdminHeaderBackground extends StatelessWidget {
  final String? title;
  
  const AdminHeaderBackground({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60, // Increased slightly for text visibility
          color: const Color(0xFF002D62),
          alignment: Alignment.center,
          padding: const EdgeInsets.only(bottom: 8),
          child: title != null
              ? Text(
                  title!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : const SizedBox(),
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