import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/widgets/main_taskbar.dart';
import 'package:soundme_frontend/features/options/presentation/screens/options_screen.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';

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
    SizedBox(), // Índice 0: Inicio
    TranslatorScreen(), // Índice 1: Traductor
    DictionaryScreen(), // Índice 2: Diccionario
    OptionsScreen(),    // Índice 3: Opciones
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