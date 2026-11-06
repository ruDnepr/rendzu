import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/presentation/providers/core_providers.dart';
import 'package:rendzu/presentation/providers/game_provider.dart';

/// Главное меню — наследует оформление «Шашек для Дианы».
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final playerName = settings?.playerName ?? 'Диана';
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    const Row(children: [Eyebrow('ИГРАЕМ ВМЕСТЕ ✦')]),
                    const SizedBox(height: 22),
                    const StoneLogo(size: 128),
                    const SizedBox(height: 22),
                    Text(
                      'Привет, $playerName!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 31,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Пять камней в ряд — и победа!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 28),
                    BigButton(
                      title: 'С компьютером',
                      subtitle: 'Выбери уровень и цвет',
                      icon: Icons.computer_rounded,
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/settings'),
                    ),
                    const SizedBox(height: 14),
                    BigButton(
                      title: 'Два игрока',
                      subtitle: 'На одном устройстве',
                      icon: Icons.people_rounded,
                      color: const Color(0xFF6047AF),
                      onPressed: () => _startLocal(
                          context, ref, GameMode.localTwoPlayers),
                    ),
                    const SizedBox(height: 14),
                    BigButton(
                      title: 'Сетевая игра',
                      subtitle: 'С другом по Wi-Fi',
                      icon: Icons.wifi_rounded,
                      color: const Color(0xFFF4CB67),
                      foreground: ink,
                      onPressed: () => _showNetworkMenu(context),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SmallMenu(
                            icon: Icons.menu_book_rounded,
                            label: 'Правила',
                            color: lilac,
                            onTap: () =>
                                Navigator.of(context).pushNamed('/rules'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SmallMenu(
                            icon: Icons.tune_rounded,
                            label: 'Настройки',
                            color: coralPeach,
                            onTap: () =>
                                Navigator.of(context).pushNamed('/settings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      backgroundColor: const Color(0xFFFFFCF6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Сетевая игра',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ChoiceTile(
              title: 'Создать игру',
              subtitle: 'Поделиться кодом с другом в одной Wi-Fi сети',
              icon: Icons.wifi_tethering_rounded,
              color: purple,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed('/net/lobby');
              },
            ),
            ChoiceTile(
              title: 'Присоединиться',
              subtitle: 'Ввести код или IP:порт от хоста',
              icon: Icons.link_rounded,
              color: const Color(0xFFF4CB67),
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
