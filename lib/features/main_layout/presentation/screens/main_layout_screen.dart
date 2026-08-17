import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/widgets/main_taskbar.dart';
import 'package:soundme_frontend/features/options/presentation/screens/options_screen.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  final int initialIndex;

  const MainLayoutScreen({
    super.key,
    this.initialIndex = 1, // Por defecto Traductor
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    SizedBox(), // Índice 0: Si toca "Inicio" en el taskbar se maneja en el onTap
    TranslatorScreen(), // Índice 1
    OptionsScreen(),    // Índice 2: Pantalla de Opciones renderizada
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: MainTaskbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            // Regresa al Menú Principal (HomeScreen)
            Navigator.pop(context);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}