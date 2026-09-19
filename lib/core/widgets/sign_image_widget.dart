import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';
import 'package:soundme_frontend/data/local/mockup_data_service.dart';

/// Widget especializado en renderizar una celda unitaria de una Sprite Sheet o Matriz Vectorial SVG.
class MatrixSignImage extends StatelessWidget {
  /// Ruta del asset de la matriz (ej. 'assets/matrices/mega_matriz_v2.svg').
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
    final isSvg = matrixAsset.toLowerCase().endsWith('.svg');
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
            child: isSvg
                ? SvgPicture.asset(
                    matrixAsset,
                    alignment: Alignment.topLeft,
                    placeholderBuilder: (context) => _buildPlaceholder(),
                  )
                : Image.asset(
                    matrixAsset,
                    alignment: Alignment.topLeft,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(fit: fit, child: cell),
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

/// Widget unificado para renderizar cualquier seña de la app, permitiendo zoom de alta fidelidad.
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
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    // 1. Renderizado prioritario de Señas Vectoriales SVG individuales (Calidad máxima, 100% nítida y sin artifacts)
    if (sign.isSvg) {
      return SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(
          sign.svgAsset!,
          fit: fit,
          width: width,
          height: height,
          placeholderBuilder: (context) => _buildPlaceholder(),
        ),
      );
    }

    // 2. Renderizado por Matriz Raster (WebP/PNG Sprite Sheets)
    if (sign.isMatrixSign && !sign.archivoMatriz!.toLowerCase().endsWith('.svg')) {
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

    // 3. Renderizado de imagen individual raster (legacy fallback)
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

  Widget _buildPlaceholder() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primaryNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sign_language_rounded,
              size: 48,
              color: AppColors.primaryNavy,
            ),
            const SizedBox(height: 8),
            Text(
              sign.palabra,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
