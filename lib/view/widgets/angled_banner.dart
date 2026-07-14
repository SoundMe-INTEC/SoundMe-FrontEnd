import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sound_me/config/theme/app_colors.dart';

/// The tilted navy-block-with-red-stripe brand graphic.
///
/// Usage:
///   AngledBanner(
///     height: 220,
///     angleDegrees: -8,
///   )
///
/// Drop it anywhere — behind a headline, as a card background accent,
/// section divider, etc. It's fully vector, so it scales perfectly at
/// any size/resolution with zero asset weight.
class AngledBanner extends StatelessWidget {
  const AngledBanner({
    super.key,
    this.height = 200,
    this.angleDegrees = -8,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.secondary,
    this.primaryThickness = 0.55,
    this.stripeThickness = 0.11,
  });

  /// Overall height of the widget. Width fills the parent.
  final double height;

  /// Tilt of the shape, in degrees. Negative tilts up to the right,
  /// matching the reference image.
  final double angleDegrees;

  final Color primaryColor;
  final Color secondaryColor;

  /// Thickness of the navy block, as a fraction of [height].
  final double primaryThickness;

  /// Thickness of the red stripe, as a fraction of [height].
  final double stripeThickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _AngledBannerPainter(
          angleDegrees: angleDegrees,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          primaryThickness: primaryThickness,
          stripeThickness: stripeThickness,
        ),
      ),
    );
  }
}

class _AngledBannerPainter extends CustomPainter {
  _AngledBannerPainter({
    required this.angleDegrees,
    required this.primaryColor,
    required this.secondaryColor,
    required this.primaryThickness,
    required this.stripeThickness,
  });

  final double angleDegrees;
  final Color primaryColor;
  final Color secondaryColor;
  final double primaryThickness;
  final double stripeThickness;
  final double centerOffset = 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = angleDegrees * math.pi / 180;

    // Navy block on top.
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.42);
    canvas.rotate(angle);
    final blockRect = Rect.fromCenter(
      // center: Offset.zero,
      center: Offset(0, -(size.height * centerOffset)),
      width: size.width * 2.0,
      height: size.height * primaryThickness * 1.45,
    );
    canvas.drawRect(blockRect, Paint()..color = primaryColor);
    canvas.restore();
    // Red stripe drawn first, sitting slightly lower and extending
    // a bit further so it peeks out from behind the navy block.
    canvas.save();
    canvas.translate(size.width * 0.52, size.height * 0.78);
    canvas.rotate(angle);
    final stripeRect = Rect.fromCenter(
      center: Offset(0, -(size.height * centerOffset)),
      width: size.width * 1.26,
      height: size.height * stripeThickness,
    );
    canvas.drawRect(stripeRect, Paint()..color = secondaryColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AngledBannerPainter oldDelegate) {
    return oldDelegate.angleDegrees != angleDegrees ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.primaryThickness != primaryThickness ||
        oldDelegate.stripeThickness != stripeThickness;
  }
}
