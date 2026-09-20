import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: topPadding),
          color: const Color(0xFF002D62),
          child: SizedBox(
            height: 52,
            child: Stack(
              children: [
                Center(
                  child: title != null
                      ? Text(
                          title!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
          color: const Color(0xFFCE1126),
        ),
      ],
    );
  }
}