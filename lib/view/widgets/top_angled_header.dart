import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'angled_banner.dart';
import 'package:sound_me/config/theme/app_colors.dart';

/// Puts [AngledBanner] at the very top of the screen, extending it
/// behind the status bar / notch (edge-to-edge) and matching the
/// system status bar icon color so it reads cleanly against navy.
///
/// Requires edge-to-edge mode to be enabled once, in main():
///
///   void main() {
///     WidgetsFlutterBinding.ensureInitialized();
///     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
///     runApp(const MyApp());
///   }
///
/// Usage in a screen:
///
///   Scaffold(
///     body: Column(
///       children: [
///         const TopAngledHeader(bannerHeight: 160),
///         Expanded(
///           child: SafeArea(
///             top: false, // header already handled the top inset
///             child: ...rest of the screen,
///           ),
///         ),
///       ],
///     ),
///   )
class TopAngledHeader extends StatelessWidget {
  const TopAngledHeader({
    super.key,
    this.bannerHeight = 160,
    this.angleDegrees = -8,
    this.darkBackground = true,
    this.child,
  });

  /// Height of the visible angled graphic, NOT including the status
  /// bar inset (that's added automatically).
  final double bannerHeight;

  final double angleDegrees;

  /// Whether the banner's background reads as dark (navy) — controls
  /// whether status bar icons/text render light or dark.
  final bool darkBackground;

  /// Optional content to lay over the banner (title, logo, etc).
  /// Positioned within the safe area, below the status bar.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final paintingHeight = statusBarHeight + bannerHeight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Android
        statusBarIconBrightness: darkBackground
            ? Brightness.light
            : Brightness.dark,
        // iOS (semantics are inverted: dark bg -> Brightness.dark)
        statusBarBrightness: darkBackground
            ? Brightness.dark
            : Brightness.light,
      ),
      child: SizedBox(
        height: paintingHeight,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            // Solid backing strip: guarantees the status bar area is
            // fully covered even where the rotated shape dips below
            // the top edge on one side.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: statusBarHeight + 1,
              child: Container(
                color: darkBackground ? AppColors.primary : AppColors.neutral,
              ),
            ),

            // The angled graphic itself, sized to fill the full header
            // (status bar inset + banner height).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: paintingHeight,
              child: AngledBanner(
                height: paintingHeight,
                angleDegrees: angleDegrees,
              ),
            ),

            // Optional overlay content, kept clear of the status bar.
            if (child != null)
              Positioned(
                top: statusBarHeight,
                left: 0,
                right: 0,
                height: bannerHeight,
                child: child!,
              ),
          ],
        ),
      ),
    );
  }
}
