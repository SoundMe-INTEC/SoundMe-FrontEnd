import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';

class MainTaskbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainTaskbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.cardFillColor,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. BOTÓN INICIO
            _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Inicio',
            ),

            // 2. BOTÓN TRADUCTOR
            _buildNavItem(
              index: 1,
              icon: Icons.g_translate_rounded,
              label: 'Traductor',
            ),

            // 3. BOTÓN OPCIONES
            _buildNavItem(
              index: 2,
              icon: Icons.settings_rounded,
              label: 'Opciones',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: AppColors.primaryNavy,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}