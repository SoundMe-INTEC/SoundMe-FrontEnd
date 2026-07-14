import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sound_me/config/routes/routes.dart';
import 'package:sound_me/config/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const SoundMe());
}

class SoundMe extends StatelessWidget {
  const SoundMe({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sound Me',
      theme: AppTheme.light,
      // home: const HomeScreen(),
      initialRoute: DefaultRoute,
      routes: AppRoutes,
    );
  }
}
