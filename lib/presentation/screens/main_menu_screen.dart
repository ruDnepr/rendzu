import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/presentation/providers/core_providers.dart';
import 'package:rendzu/presentation/providers/game_provider.dart';

/// Главное меню: выбор режима игры и доступ к правилам/настройкам.
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final playerName = settings?.playerName ?? 'Диана';
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cream, AppColors.creamDark],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      // Логотип-камни — крупнее
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LogoStone(
                              color: AppColors.stoneBlack,
                              hi: AppColors.stoneBlackHi,
                              size: 56),
                          const SizedBox(width: 18),
                          _LogoStone(
                              color: AppColors.stoneWhite,
                              hi: AppColors.stoneWhite,
                              edge: AppColors.stoneWhiteEdge,
                              size: 56),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('Привет, $playerName!',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 6),
                      Text('Пять камней в ряд — и победа!',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _MenuButton(
                        icon: Icons.computer,
                        label: 'С компьютером',
                        color: AppColors.coral,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/settings'),
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        icon: Icons.people,
                        label: 'Два игрока',
                        color: AppColors.sky,
                        onTap: () => _startLocal(
                            context, ref, GameMode.localTwoPlayers),
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        icon: Icons.wifi,
                        label: 'Играть по сети',
                        color: const Color(0xFFE69A00),
                        onTap: () => _showNetworkMenu(context),
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        icon: Icons.menu_book,
                        label: 'Правила',
                        color: AppColors.grass,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/rules'),
                      ),
                      const SizedBox(height: 12),
                      _MenuButton(
                        icon: Icons.settings,
                        label: 'Настройки',
                        color: AppColors.textMid,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startLocal(BuildContext context, WidgetRef ref, GameMode mode) {
    final settings = ref.read(settingsServiceProvider);
    final config = GameConfig(
      ruleset: _readRuleset(settings?.ruleset),
      boardSize: _readBoardSize(settings?.boardSize),
      mode: mode,
      difficulty: _readDifficulty(settings?.difficulty),
      hintsEnabled: settings?.hintsEnabled ?? true,
      patternHighlightEnabled: settings?.patternHighlight ?? true,
      soundEnabled: settings?.soundEnabled ?? true,
      humanColor: StoneColor.black,
      hostPlayerName: settings?.playerName ?? 'Игрок 1',
      clientPlayerName: 'Игрок 2',
    );
    ref.read(gameConfigProvider.notifier).state = config;
    Navigator.of(context).pushNamed('/game');
  }

  void _showNetworkMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Сетевая игра', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.wifi_tethering, color: AppColors.coral),
              title: const Text('Создать игру (хост)'),
              subtitle: const Text('Поделиться кодом с другом в одной Wi-Fi сети'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed('/net/lobby');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.sky),
              title: const Text('Присоединиться по коду'),
              subtitle: const Text('Ввести код или IP:порт от хоста'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed('/net/join');
              },
            ),
          ],
        ),
      ),
    );
  }

  Ruleset _readRuleset(String? s) =>
      s == 'renju' ? Ruleset.renju : Ruleset.gomoku;
  BoardSize _readBoardSize(String? s) =>
      s == 'standard15' ? BoardSize.standard15 : BoardSize.small9;
  Difficulty _readDifficulty(String? s) => switch (s) {
        'medium' => Difficulty.medium,
        'hard' => Difficulty.hard,
        _ => Difficulty.easy,
      };
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.warmWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(label, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textMid, size: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoStone extends StatelessWidget {
  const _LogoStone({required this.color, required this.hi, this.edge, this.size = 44});
  final Color color;
  final Color hi;
  final Color? edge;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [hi, color],
          stops: const [0.0, 0.7],
        ),
        border: edge != null ? Border.all(color: edge!, width: 1.5) : null,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
    );
  }
}
