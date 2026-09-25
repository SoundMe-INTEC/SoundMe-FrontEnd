import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/widgets/header_background_2.dart';

class HeaderWithBackButton extends StatelessWidget {
  final String? title;
  final VoidCallback? onBack;
  
  const HeaderWithBackButton({super.key, this.title, this.onBack});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final canPop = Navigator.canPop(context);

    return Stack(
      children: [
        // El banner original con el título
        AdminHeaderBackground(title: title),

        // El botón de regresar (se muestra si existe callback explícito o si la ruta permite volver)
        if (onBack != null || canPop)
          Positioned(
            top: topPadding + 4,
            left: 6,
            child: SizedBox(
              height: 44,
              width: 44,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  tooltip: 'Regresar',
                  padding: EdgeInsets.zero,
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
