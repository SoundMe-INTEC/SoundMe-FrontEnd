import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';

class HeaderWithBackButton extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  
  const HeaderWithBackButton({super.key, this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        // El banner original con el título
        AdminHeaderBackground(title: title),
        // El botón de regresar
        Positioned(
          top: topPadding,
          left: 4,
          child: SizedBox(
            height: 52,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                tooltip: 'Regresar',
                onPressed: () {
                  if (onBack != null) {
                    onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
