import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BANNER SUPERIOR DE ADMIN
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBackground(),
          ),

          // 2. CONTENIDO PRINCIPAL
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 11),

                  // TÍTULOS
                  const Text(
                    'Panel de Administración',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD: USUARIOS ACTIVOS
                  _buildStatCard(
                    title: 'Usuarios Activos',
                    value: '1,234',
                    backgroundColor: AppColors.primaryNavy,
                    icon: Icons.group,
                  ),

                  const SizedBox(height: 20),

                  // CARD: TRADUCCIONES REALIZADAS
                  _buildStatCard(
                    title: 'Traducciones Realizadas',
                    value: '5,678',
                    backgroundColor: AppColors.cardBlue,
                    icon: Icons.g_translate,
                  ),

                  const SizedBox(height: 20),

                  // SECCIÓN: ACCIONES RÁPIDAS
                  const Text(
                    'Acciones Rápidas',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // BOTÓN: GESTIONAR DICCIONARIO
                  SizedBox(
                    width: double.infinity,
                    height: 59,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Ir a Diccionario
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book, size: 28),
                      label: const Text(
                        'Gestionar Diccionario',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // BOTÓN: REVISAR VALORACIONES
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Ir a Valoraciones
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.textGray, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      icon: const Icon(Icons.rate_review, size: 28, color: Colors.black),
                      label: const Text(
                        'Revisar Valoraciones',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // BOTÓN: CERRAR SESIÓN
                  Center(
                    child: SizedBox(
                      width: 189,
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () {
                          // Lógica de logout -> Regresar al Home o Login
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentRed,
                          side: const BorderSide(color: AppColors.accentRed, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // LOGO AL FINAL
                  const Center(child: SoundMeLogo()),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para las tarjetas de estadísticas con icono
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 127,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Icon(
            icon,
            size: 70,
            color: Colors.white.withAlpha(180),
          ),
        ],
      ),
    );
  }
}