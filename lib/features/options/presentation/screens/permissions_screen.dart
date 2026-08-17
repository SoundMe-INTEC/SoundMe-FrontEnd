import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationsEnabled = false;
  bool _microphoneEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Banner decorativo superior
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBackground(),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // Título de la pantalla
                        const Text(
                          'PERMISOS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryNavy,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Tarjeta: Notificaciones
                        _buildToggleCard(
                          icon: Icons.notifications_none,
                          title: 'Notificaciones',
                          subtitle:
                          'Activa las notificaciones de la aplicación.',
                          value: _notificationsEnabled,
                          onChanged: (bool value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Tarjeta: Micrófono
                        _buildToggleCard(
                          icon: Icons.mic_none,
                          title: 'Micrófono',
                          subtitle: 'Permite a la app usar tu micrófono.',
                          value: _microphoneEnabled,
                          onChanged: (bool value) {
                            setState(() {
                              _microphoneEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Empuja el logo a la parte inferior disponible de la pantalla
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        SizedBox(height: 24),
                        SizedBox(
                          width: 270,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SoundMeLogo(),
                          ),
                        ),
                        SizedBox(height: 24), // Margen inferior de seguridad
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Componente reutilizable para los elementos con Switch
  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryNavy,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: AppColors.primaryNavy.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primaryNavy,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}