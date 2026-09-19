import 'package:flutter/material.dart';
import 'package:soundme_frontend/core/widgets/main_taskbar.dart';
import 'package:soundme_frontend/features/options/presentation/screens/options_screen.dart';
import 'package:soundme_frontend/features/translator/presentation/screens/translator_screen.dart';
import 'package:soundme_frontend/features/dictionary/presentation/dictionary_screen.dart';
import 'package:soundme_frontend/core/theme/app_colors.dart';

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
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    final Widget body = IndexedStack(
      index: _currentIndex,
      children: _screens,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: isWideScreen
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.cardFillColor,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (int index) {
                    if (index == 0) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _currentIndex = index;
                      });
                    }
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AppColors.primaryNavy, size: 28),
                  unselectedIconTheme: const IconThemeData(color: AppColors.primaryNavy, size: 26),
                  selectedLabelTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
                  unselectedLabelTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                  indicatorColor: AppColors.accentLightBlue,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_rounded),
                      label: Text('Inicio'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.g_translate_rounded),
                      label: Text('Traductor'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_rounded),
                      label: Text('Diccionario'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_rounded),
                      label: Text('Opciones'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1, color: Colors.black12),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isWideScreen
          ? null
          : MainTaskbar(
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