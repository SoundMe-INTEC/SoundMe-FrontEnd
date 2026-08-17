import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';
import 'package:soundme_frontend/core/widgets/soundme_logo.dart';
import 'package:soundme_frontend/features/options/presentation/screens/permissions_screen.dart';

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Título de la pantalla
                  const Text(
                    'Opciones',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta: Historial
                  _buildOptionCard(
                    icon: Icons.history,
                    title: 'Historial',
                    subtitle: 'Revisa tus traducciones pasadas',
                    onTap: () {},
                  ),

                  const SizedBox(height: 16),

                  // Bloque: Diccionario y Categorías
                  _buildDictionaryGroup(context),

                  const SizedBox(height: 16),

                  // Tarjeta: Notificaciones y Permisos
                  _buildOptionCard(
                    icon: Icons.notifications_none,
                    title: 'Notificaciones y Permisos',
                    subtitle: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PermissionsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Widget del Logo oficial de SoundMe
                  Center(
                    child: SizedBox(
                      width: 290, // Ajusta el ancho deseado
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SoundMeLogo(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget reutilizable para tarjetas principales
  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, color: AppColors.primaryNavy, size: 36),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryNavy,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: AppColors.primaryNavy.withOpacity(0.8),
          ),
        )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.primaryNavy,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  // Grupo colapsable / desplegado del Diccionario
  Widget _buildDictionaryGroup(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFillColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade400, width: 0.8),
      ),
      child: Column(
        children: [
          // Cabecera del Diccionario
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book,
                  color: AppColors.primaryNavy,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diccionario',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Busca las palabras/frases que gustes y su interpretación en señas',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: AppColors.primaryNavy.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaryNavy,
                ),
              ],
            ),
          ),

          // Sub-elementos integrados
          _buildSubCategoryItem(
            title: 'Saludos básicos',
            onTap: () {},
          ),
          _buildSubCategoryItem(
            title: 'Frases comunes',
            onTap: () {},
          ),
          _buildSubCategoryItem(
            title: 'Emergencias',
            isLast: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // Ítem de subcategoría
  Widget _buildSubCategoryItem({
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.8),
        ),
        borderRadius: isLast
            ? const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        )
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryNavy,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.primaryNavy,
          size: 14,
        ),
        onTap: onTap,
      ),
    );
  }
}