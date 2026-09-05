import 'package:flutter/material.dart';

class AdminHeaderBackground extends StatelessWidget {
  final String? title;
  
  const AdminHeaderBackground({super.key, this.title});

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
            child: Center(
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