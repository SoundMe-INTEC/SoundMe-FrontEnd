import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_with_back_button.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';
import 'package:soundme_frontend/features/auth/data/auth_service.dart';
import 'package:soundme_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:soundme_frontend/features/home/presentation/screens/home_screen.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockData = ref.watch(allMockSignsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. CONTENIDO PRINCIPAL
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 65),
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
                    error: (_, _) => _buildStatCard(
                      title: 'Señas en Diccionario',
                      value: '—',
                      backgroundColor: AppColors.primaryNavy,
                      icon: Icons.menu_book,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CARD: TRADUCCIONES (mockup con texto navy accesible WCAG AA 4.89:1)
                  _buildStatCard(
                    title: 'Traducciones Realizadas',
                    value: '128',
                    backgroundColor: AppColors.cardBlue,
                    icon: Icons.g_translate,
                    textColor: AppColors.cardBlueText,
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
                        side: const BorderSide(
                          color: AppColors.textGray,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      icon: const Icon(
                        Icons.rate_review,
                        size: 28,
                        color: Colors.black,
                      ),
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
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al cerrar sesión: $e'),
                            ),
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

          // 2. BANNER SUPERIOR DE ADMIN CON RETORNO (al final del Stack para recibir toques)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderWithBackButton(
              title: 'Panel de Administración',
              onBack: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              },
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
    Color textColor = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 70, color: textColor.withAlpha(180)),
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
    return Material(
      color: AppColors.cardFillColor,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
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
