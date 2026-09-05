import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';

class SoundMeLogo extends StatelessWidget {
  const SoundMeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 315,
            maxHeight: 180,
          ),
          child: AspectRatio(
            aspectRatio: 315 / 180,
            child: Image.asset(
              'assets/images/soundme_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.hearing,
                size: 60,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Traductor de Voz a Lengua de\nSeñas Dominicana',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textGray,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}