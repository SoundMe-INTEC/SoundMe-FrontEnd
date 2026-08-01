import 'package:flutter/material.dart';
import 'package:soundme_frontend/features/home/screens/about_screen.dart';
import 'package:soundme_frontend/features/home/widgets/header_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Definición de colores según el diseño de Figma
  static const Color primaryNavy = Color(0xFF002D62);
  static const Color accentRed = Color(0xFFCE1126);
  static const Color textGray = Color(0xFF747474);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // El Stack principal ocupa TODA la pantalla (incluyendo la barra de estado)
      body: Stack(
        children: [
          // 1. DECORACIÓN DE FONDO REUTILIZABLE
          const HeaderBackground(),

          // 2. CONTENIDO INTERACTIVO
          SafeArea(
            child: Stack(
              children: [
                // BOTÓN DE ADMINISTRADORES (Esquina superior derecha)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildAdminButton(context),
                ),

                // CONTENIDO PRINCIPAL (Centrado)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // LOGO Y SUBTÍTULO
                      Column(
                        children: [
                          const SizedBox(height: 60),
                          Image.asset(
                            'assets/images/soundme_logo.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Traductor de Voz a Lengua de\nSeñas Dominicana',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: textGray,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(flex: 2),

                      // BOTONES DE ACCIÓN
                      _buildPrimaryButton(
                        text: 'Traductor',
                        icon: Icons.g_translate,
                        onPressed: () {
                          // TODO: Navegar al Traductor
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildSecondaryButton(
                        text: 'Opciones',
                        icon: Icons.settings_outlined,
                        onPressed: () {
                          // TODO: Navegar a Opciones
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildSecondaryButton(
                        text: 'Sobre Nosotros',
                        icon: Icons.info_outline,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),

                      const Spacer(flex: 3),

                      // COPYRIGHT FOOTER
                      const Text(
                        '© 2026 SoundMe. Todos los derechos reservados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: textGray,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  // Botón Principal Azul (Traductor)
  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Botones Secundarios Bordeados (Opciones, Sobre Nosotros)
  Widget _buildSecondaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: const BorderSide(color: textGray, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        icon: Icon(icon, size: 28, color: Colors.black),
        label: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // Botón de Administradores
  Widget _buildAdminButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navegar a Admin
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 10),
          Icon(Icons.manage_accounts_outlined, color: primaryNavy, size: 40),
        ],
      ),
    );
  }
}