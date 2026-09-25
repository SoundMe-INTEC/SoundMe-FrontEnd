import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';

class AdminHeaderBackground extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final List<Widget>? actions;
  
  const AdminHeaderBackground({
    super.key,
    this.title,
    this.trailing,
    this.actions,
  });

  static double headerHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 65.0;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: topPadding),
          decoration: const BoxDecoration(
            color: AppColors.primaryNavy,
          ),
          child: SizedBox(
            height: 52,
            child: Stack(
              children: [
                Center(
                  child: title != null
                      ? Text(
                          title!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        )
                      : const SizedBox(),
                ),
                if (trailing != null)
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(child: trailing!),
                  )
                else if (actions != null && actions!.isNotEmpty)
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 13,
          color: AppColors.accentRed,
        ),
      ],
    );
  }
}