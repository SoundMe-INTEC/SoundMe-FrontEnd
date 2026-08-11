import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. FONDO REUTILIZABLE
          const HeaderBackground(),

          // 2. CONTENIDO PRINCIPAL SCROLLABLE
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),

                        // LOGO Y SUBTÍTULO
                        const SoundMeLogo(),

                        const SizedBox(height: 28),

                        // TÍTULO: NUESTRO OBJETIVO
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nuestro Objetivo',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // IMAGEN DE COMUNIDAD CON BORDES REDONDEADOS
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/images/about_us.png',
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 188,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 50,
                                color: AppColors.textGray,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // DESCRIPCIÓN
                        const Text(
                          'En un mundo diseñado para ser escuchado, el silencio no debería ser una barrera para la comprensión. SoundMe nace con la misión de transformar la voz en imágenes, devolviendo la fluidez a las conversaciones y garantizando que cada mensaje, sin importar cómo se transmita, llegue con claridad al corazón de la comunidad sorda. Creemos que la conexión humana es un derecho, no un privilegio, y trabajamos para que nadie vuelva a quedar fuera de la charla.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // COPYRIGHT FOOTER
                        const Text(
                          '© 2026 SoundMe. Todos los derechos reservados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}