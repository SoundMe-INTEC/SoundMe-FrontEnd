import 'package:flutter/material.dart';
import 'package:sound_me/view/widgets/logo_slogan.dart';
import 'package:sound_me/view/widgets/nav_button.dart';
import 'package:sound_me/view/widgets/top_angled_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: .spaceBetween,
        children: [
          Column(
            children: [
              const TopAngledHeader(angleDegrees: -16),
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                  child: Column(
                    // mainAxisAlignment: .spaceEvenly,
                    spacing: 50,
                    children: [
                      LogoSlogan(
                        message:
                            "Traductor de Voz a Lengua de Señas Dominicana",
                      ),
                      Column(
                        spacing: 24,
                        children: [
                          NavButton(
                            title: "Traductor",
                            icon: 'hands',
                            destination: '/translate',
                          ),
                          NavButton(
                            title: "Opciones",
                            outline: true,
                            icon: 'setting',
                            destination: '/settings',
                          ),
                          NavButton(
                            title: "Sobre Nosotros",
                            outline: true,
                            icon: 'info',
                            destination: '/about-us',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 32),
            child: Text(
              "© 2026 SoundMe. Todos los derechos reservados.",
              style: TextStyle(fontSize: 14, color: Color(0xff747474)),
            ),
          ),
        ],
      ),
    );
  }
}
