import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/learning_provider.dart';
import 'screens/game_screen.dart';
import 'screens/learning_path_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  final learningProvider = LearningProvider();
  await learningProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider.value(value: learningProvider),
      ],
      child: const LudoKingApp(),
    ),
  );
}

class LudoKingApp extends StatelessWidget {
  const LudoKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo King HD',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (_) => const MainMenuScreen(),
        '/game': (_) => const _GameScreenWithOverlay(),
        '/learn': (_) => const LearningPathScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

/// Wraps the game screen with the game-over overlay.
class _GameScreenWithOverlay extends StatelessWidget {
  const _GameScreenWithOverlay();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        GameScreen(),
        GameOverOverlay(),
      ],
    );
  }
}
