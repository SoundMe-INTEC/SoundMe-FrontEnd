import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';

class HeaderWithBackButton extends StatelessWidget {
  final String? title;
  
  const HeaderWithBackButton({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // El banner original con el título
        AdminHeaderBackground(title: title),
        // El botón de regresar
        Positioned(
          top: 0,
          left: 0,
          bottom: 13, // To keep it centered in the blue area (13 is red area height)
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ],
    );
  }
}
