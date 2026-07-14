import 'package:flutter/material.dart';

class LogoSlogan extends StatelessWidget {
  const LogoSlogan({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image(image: AssetImage('assets/logo.png')),
        Container(
          constraints: BoxConstraints(maxWidth: 240),
          child: Text(
            message,
            softWrap: true,
            textAlign: .center,
            style: TextStyle(color: Color(0xff747474)),
          ),
        ),
      ],
    );
  }
}
