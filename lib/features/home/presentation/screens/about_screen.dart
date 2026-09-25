import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headerTopOffset = AdminHeaderBackground.headerHeight(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. CABECERA FIJA CON BOTÓN DE REGRESAR
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(title: 'Sobre Nosotros'),
          ),

          // 2. CONTENIDO PRINCIPAL CON PADDING SUPERIOR EXACTO
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                top: headerTopOffset - MediaQuery.paddingOf(context).top,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LOGO EN ÁREA BLANCA LIMPIA (SCROLL SIN COLISIÓN)
                    const SoundMeLogo(),
                    const SizedBox(height: 24),

                    // TARJETA DE ILUSTRACIÓN PRINCIPAL
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: AppColors.cardShadow,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset(
                          'assets/images/about_us.png',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppColors.cardFillColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.cardBorderColor,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      size: 48,
                                      color: AppColors.primaryNavy,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Conexión e Inclusión Dominicana',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TARJETA DE NUESTRO OBJETIVO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        color: AppColors.cardFillColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorderColor),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.center_focus_strong_rounded,
                                  color: AppColors.primaryNavy,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Nuestro Objetivo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'En un mundo diseñado para ser escuchado, el silencio no debería ser una barrera para la comprensión. SoundMe nace con la misión de transformar la voz en imágenes, devolviendo la fluidez a las conversaciones y garantizando que cada mensaje, sin importar cómo se transmita, llegue con claridad al corazón de la comunidad sorda.',
                            textAlign: TextAlign.justify,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PILLS DE VALORES / PILARES
                    Row(
                      children: [
                        Expanded(
                          child: _buildValueChip(
                            icon: Icons.diversity_3_rounded,
                            label: 'Inclusión',
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildValueChip(
                            icon: Icons.record_voice_over_rounded,
                            label: 'Voz & Señas',
                            color: AppColors.accentRed,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildValueChip(
                            icon: Icons.verified_user_rounded,
                            label: 'Accesible',
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    Text(
                      '© 2026 SoundMe. Todos los derechos reservados.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
