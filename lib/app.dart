import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/presentation/screens/game_screen.dart';
import 'package:rendzu/presentation/screens/main_menu_screen.dart';
import 'package:rendzu/presentation/screens/network_join_screen.dart';
import 'package:rendzu/presentation/screens/network_lobby_screen.dart';
import 'package:rendzu/presentation/screens/rules_screen.dart';
import 'package:rendzu/presentation/screens/settings_screen.dart';
import 'package:rendzu/presentation/screens/splash_screen.dart';

class RendzuApp extends ConsumerWidget {
  const RendzuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Рэндзю для Дианы',
      debugShowCheckedModeBanner: false,
      theme: dianaTheme(),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/menu': (context) => const MainMenuScreen(),
        '/rules': (context) => const RulesScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/game': (context) => const GameScreen(),
        '/net/lobby': (context) => const NetworkLobbyScreen(),
        '/net/join': (context) => const NetworkJoinScreen(),
      },
    );
  }
}
