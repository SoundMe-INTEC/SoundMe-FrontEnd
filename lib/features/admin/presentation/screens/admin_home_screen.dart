import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/auth/data/auth_service.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:soundme_frontend/features/dictionary/presentation/screens/dictionary_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockData = ref.watch(allMockSignsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. BANNER SUPERIOR DE ADMIN
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHeaderBackground(title: 'Panel de Administración'),
          ),

          // 2. CONTENIDO PRINCIPAL
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    '¡Bienvenido, Administrador!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD: SEÑAS EN DICCIONARIO (dato dinámico del mockup)
                  mockData.when(
                    data: (signs) => _buildStatCard(
                      title: 'Señas en Diccionario',
                      value: '${signs.length}',
                      backgroundColor: AppColors.primaryNavy,
                      icon: Icons.menu_book,
                    ),
                    loading: () => _buildStatCard(
                      title: 'Señas en Diccionario',
                      value: '...',
                      backgroundColor: AppColors.primaryNavy,
                      icon: Icons.menu_book,
                    ),
                    error: (_, __) => _buildStatCard(
                      title: 'Señas en Diccionario',
                      value: '—',
                      backgroundColor: AppColors.primaryNavy,
                      icon: Icons.menu_book,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CARD: TRADUCCIONES (mockup)
                  _buildStatCard(
                    title: 'Traducciones Realizadas',
                    value: '128',
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

                  // BOTÓN: GESTIONAR DICCIONARIO — Ahora navega a DictionaryScreen
                  SizedBox(
                    width: double.infinity,
                    height: 59,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DictionaryScreen(),
                          ),
                        );
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

                  // Tarjeta: Cerrar sesión
                  _buildOptionCard(
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    subtitle: 'Cierra tu sesión en este dispositivo',
                    iconColor: Colors.red,
                    titleColor: Colors.red,
                    onTap: () async {
                      try {
                        await ref.read(authServiceProvider).logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al cerrar sesión: $e')),
                          );
                        }
                      }
                    },
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
          Expanded(
            child: Column(
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

  // Widget reutilizable para tarjetas de opciones
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Icon(
          icon,
          color: iconColor ?? AppColors.primaryNavy,
          size: 36,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: titleColor ?? AppColors.primaryNavy,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: (titleColor ?? AppColors.primaryNavy).withAlpha(204),
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: iconColor ?? AppColors.primaryNavy,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }
}