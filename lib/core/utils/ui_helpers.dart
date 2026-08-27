import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/presentation/widgets/error_modal.dart';

class UIHelpers {
  /// Muestra un overlay de carga inmodificable
  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryNavy,
        ),
      ),
    );
  }

  /// Oculta el overlay de carga actual
  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Muestra un SnackBar de éxito estandarizado
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Muestra el modal de error y ofrece reintentar
  static void showError(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
    VoidCallback? onCancel,
  }) {
    ErrorModal.show(
      context,
      title: 'Ha ocurrido un error',
      message: message,
      onRetry: onRetry,
      onCancel: onCancel,
    );
  }
}
