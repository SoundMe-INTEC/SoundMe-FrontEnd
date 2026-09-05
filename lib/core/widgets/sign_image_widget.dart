import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

/// Widget especializado en renderizar una celda unitaria de una Sprite Sheet (matriz WebP).
///
/// Utiliza transformación y recorte por hardware (GPU) sin decodificación extra en CPU,
/// aprovechando el [ImageCache] nativo de Flutter para un rendimiento óptimo de 60/120 FPS.
class MatrixSignImage extends StatelessWidget {
  /// Ruta del asset de la matriz (ej. 'assets/matrices/matriz_a_01.webp').
  final String matrixAsset;

  /// Coordenadas de la celda dentro de la matriz en píxeles (x, y, width, height).
  final Rect coordinates;

  /// Modo de ajuste de la celda al espacio disponible.
  final BoxFit fit;

  /// Ancho opcional del widget contenedor.
  final double? width;

  /// Alto opcional del widget contenedor.
  final double? height;

  const MatrixSignImage({
    super.key,
    required this.matrixAsset,
    required this.coordinates,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Celda de tamaño exacto a las coordenadas (ej. 200x200 px),
    // desplazando la matriz mediante Transform.translate para que solo la celda deseada sea visible.
    final Widget cell = SizedBox(
      width: coordinates.width,
      height: coordinates.height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Transform.translate(
            offset: Offset(-coordinates.left, -coordinates.top),
            child: Image.asset(
              matrixAsset,
              alignment: Alignment.topLeft,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: fit,
        child: cell,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: coordinates.width,
      height: coordinates.height,
      color: Colors.white,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppColors.primaryNavy,
        ),
      ),
    );
  }
}

/// Widget unificado para renderizar cualquier seña de la app.
///
/// Soporta automáticamente tanto las señas modernas por matriz WebP como
/// las señas heredadas con ruta de imagen PNG individual.
class SignImage extends StatelessWidget {
  final MockSignEntry sign;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SignImage({
    super.key,
    required this.sign,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (sign.isMatrixSign) {
      final assetPath = sign.archivoMatriz!.startsWith('assets/')
          ? sign.archivoMatriz!
          : 'assets/matrices/${sign.archivoMatriz}';

      return MatrixSignImage(
        matrixAsset: assetPath,
        coordinates: sign.coordenadas!,
        fit: fit,
        width: width,
        height: height,
      );
    }

    if (sign.imagenAsset.isNotEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          sign.imagenAsset,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          color: AppColors.primaryNavy,
        ),
      ),
    );
  }
}
