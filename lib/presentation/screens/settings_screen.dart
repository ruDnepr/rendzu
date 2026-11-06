import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/presentation/providers/core_providers.dart';
import 'package:rendzu/presentation/providers/game_provider.dart';

/// Экран настроек: выбираем набор правил, размер доски, уровень ИИ, цвет,
/// подсказки, звук, имя игрока. Отсюда же запускаем игру.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Ruleset _ruleset;
  late BoardSize _boardSize;
  late Difficulty _difficulty;
  late StoneColor _humanColor;
  late bool _hints;
  late bool _pattern;
  late bool _sound;
  late TextEditingController _nameCtrl;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final s = ref.read(settingsServiceProvider);
    _ruleset = s?.ruleset == 'renju' ? Ruleset.renju : Ruleset.gomoku;
    _boardSize = s?.boardSize == 'standard15'
        ? BoardSize.standard15
        : BoardSize.small9;
    _difficulty = switch (s?.difficulty) {
      'medium' => Difficulty.medium,
      'hard' => Difficulty.hard,
      _ => Difficulty.easy,
    };
    _humanColor = StoneColor.black;
    _hints = s?.hintsEnabled ?? true;
    _pattern = s?.patternHighlight ?? true;
    _sound = s?.soundEnabled ?? true;
    _nameCtrl = TextEditingController(text: s?.playerName ?? 'Диана');
    _loaded = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _persist() {
    final s = ref.read(settingsServiceProvider);
    if (s == null) return;
    s.ruleset = _ruleset.name;
    s.boardSize = _boardSize.name;
    s.difficulty = _difficulty.name;
    s.hintsEnabled = _hints;
    s.patternHighlight = _pattern;
    s.soundEnabled = _sound;
    s.playerName = _nameCtrl.text.trim().isEmpty
        ? 'Игрок'
        : _nameCtrl.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('Набор правил'),
            _ChoiceRow<Ruleset>(
              value: _ruleset,
              values: Ruleset.values,
              label: (r) => r.russianName,
              onChanged: (v) => setState(() => _ruleset = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(_ruleset.russianDescription,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            _SectionTitle('Размер доски'),
            _ChoiceRow<BoardSize>(
              value: _boardSize,
              values: BoardSize.values,
              label: (b) => b.russianName,
              onChanged: (v) => setState(() => _boardSize = v),
            ),
            const SizedBox(height: 12),
            _SectionTitle('Уровень компьютера'),
            _ChoiceRow<Difficulty>(
              value: _difficulty,
              values: Difficulty.values,
              label: (d) => d.russianName,
              onChanged: (v) => setState(() => _difficulty = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(_difficulty.russianDescription,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            _SectionTitle('Твой цвет (против компьютера)'),
            _ChoiceRow<StoneColor>(
              value: _humanColor,
              values: StoneColor.values,
              label: (c) => c.russianName,
              onChanged: (v) => setState(() => _humanColor = v),
            ),
            const SizedBox(height: 12),
            _SectionTitle('Помощь и звук'),
            _SwitchTile(
              title: 'Подсказки возможных ходов',
              value: _hints,
              onChanged: (v) => setState(() => _hints = v),
            ),
            _SwitchTile(
              title: 'Подсветка троек и четвёрок',
              value: _pattern,
              onChanged: (v) => setState(() => _pattern = v),
            ),
            _SwitchTile(
              title: 'Звук',
              value: _sound,
              onChanged: (v) => setState(() => _sound = v),
            ),
            const SizedBox(height: 12),
            _SectionTitle('Имя игрока'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Введи имя',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.computer),
                    label: const Text('С компьютером'),
                    onPressed: () => _start(GameMode.vsComputer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sky,
                    ),
                    icon: const Icon(Icons.people),
                    label: const Text('Двое'),
                    onPressed: () => _start(GameMode.localTwoPlayers),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Сохранить настройки'),
              onPressed: () {
                _persist();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Настройки сохранены!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _start(GameMode mode) {
    _persist();
    final config = GameConfig(
      ruleset: _ruleset,
      boardSize: _boardSize,
      mode: mode,
      difficulty: _difficulty,
      hintsEnabled: _hints,
      patternHighlightEnabled: _pattern,
      soundEnabled: _sound,
      humanColor: _humanColor,
      hostPlayerName: _nameCtrl.text.trim().isEmpty
          ? 'Игрок 1'
          : _nameCtrl.text.trim(),
      clientPlayerName: 'Игрок 2',
    );
    ref.read(gameConfigProvider.notifier).state = config;
    Navigator.of(context).pushNamed('/game');
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });
  final T value;
  final List<T> values;
  final String Function(T) label;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final selected = v == value;
        return ChoiceChip(
          label: Text(label(v)),
          selected: selected,
          onSelected: (_) => onChanged(v),
          selectedColor: AppColors.coral.withOpacity(0.25),
          labelStyle: TextStyle(
            fontFamily: 'Baloo2',
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.coralDark : AppColors.textMid,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? AppColors.coral : AppColors.textLight,
              width: selected ? 2 : 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.coral,
    );
  }
}
