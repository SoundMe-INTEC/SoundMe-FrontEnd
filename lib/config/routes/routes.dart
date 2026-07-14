import 'package:flutter/widgets.dart';
import 'package:sound_me/view/screens/about_us_screen.dart';
import 'package:sound_me/view/screens/home_screen.dart';
import 'package:sound_me/view/screens/setting_screen.dart';
import 'package:sound_me/view/screens/translate_screen.dart';

final Map<String, Widget Function(BuildContext)> AppRoutes = {
  '/': (context) => const HomeScreen(),
  '/settings': (context) => const SettingScreen(),
  '/translate': (context) => const TranslateScreen(),
  '/about-us': (context) => const AboutUsScreen(),
};

const String DefaultRoute = '/';
