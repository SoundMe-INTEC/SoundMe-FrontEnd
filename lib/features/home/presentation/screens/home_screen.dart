import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:soundme_frontend/features/home/presentation/screens/about_screen.dart';
import 'package:soundme_frontend/features/main_layout/presentation/screens/main_layout_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. DECORACIÓN DE FONDO REUTILIZABLE
          const HeaderBackground(),

          // 2. CONTENIDO INTERACTIVO
          SafeArea(
            child: Stack(
              children: [
                // CONTENIDO PRINCIPAL SCROLLABLE
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      // LOGO Y SUBTÍTULO
                      const SizedBox(height: 160),
                      const SoundMeLogo(),
                      const SizedBox(height: 32),

                      // BOTONES DE ACCIÓN
                      _buildPrimaryButton(
                        text: 'Traductor',
                        icon: Icons.g_translate,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainLayoutScreen(initialIndex: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildSecondaryButton(
                        text: 'Opciones',
                        icon: Icons.settings_outlined,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainLayoutScreen(initialIndex: 3),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

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

                      const SizedBox(height: 40),

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

                // BOTÓN DE ADMINISTRADORES (encima del scroll para recibir toques)
                Positioned(
                  top: 12,
                  right: 16,
                  child: _buildAdminButton(context),
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
          backgroundColor: AppColors.primaryNavy, // Uso de AppColors
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
          side: const BorderSide(
            color: AppColors.textGray,
            width: 2,
          ), // Uso de AppColors
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
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 10),
          Icon(
            Icons.manage_accounts_outlined,
            color: AppColors.primaryNavy,
            size: 40,
          ), // Uso de AppColors
        ],
      ),
    );
  }
}
