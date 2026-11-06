import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/presentation/providers/core_providers.dart';
import 'package:rendzu/presentation/providers/game_provider.dart';

/// Экран настроек и запуска партии — наследует оформление «Шашек для Дианы».
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
    s.playerName =
        _nameCtrl.text.trim().isEmpty ? 'Игрок' : _nameCtrl.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Настройки',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const Intro(
              eyebrow: 'ПАРТИЯ ✦',
              title: 'Выбери правила',
              subtitle: 'Гомоку — проще, рэндзю — с запретами для чёрных.'),
          const SizedBox(height: 18),
          _Section('Набор правил'),
          _ChoiceRow(_ruleset, Ruleset.values, (r) => r.russianName,
              (v) => setState(() => _ruleset = v)),
          _Hint(_ruleset.russianDescription),
          _Section('Размер доски'),
          _ChoiceRow(_boardSize, BoardSize.values, (b) => b.russianName,
              (v) => setState(() => _boardSize = v)),
          _Section('Уровень компьютера'),
          _ChoiceRow(_difficulty, Difficulty.values, (d) => d.russianName,
              (v) => setState(() => _difficulty = v)),
          _Hint(_difficulty.russianDescription),
          _Section('Твой цвет (против компьютера)'),
          _ChoiceRow(_humanColor, StoneColor.values, (c) => c.russianName,
              (v) => setState(() => _humanColor = v)),
          _Section('Помощь и звук'),
          _SwitchTile('Подсказки возможных ходов', _hints,
              (v) => setState(() => _hints = v)),
          _SwitchTile('Подсветка троек и четвёрок', _pattern,
              (v) => setState(() => _pattern = v)),
          _SwitchTile(
              'Звук', _sound, (v) => setState(() => _sound = v)),
          _Section('Имя игрока'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE3D8F5)),
                ),
                hintText: 'Введи имя',
              ),
            ),
          ),
          const SizedBox(height: 22),
          BigButton(
            title: 'Играть с компьютером',
            icon: Icons.play_arrow_rounded,
            onPressed: () => _start(GameMode.vsComputer),
          ),
          const SizedBox(height: 12),
          BigButton(
            title: 'Два игрока',
            icon: Icons.people_rounded,
            color: const Color(0xFF6047AF),
            onPressed: () => _start(GameMode.localTwoPlayers),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE3D8F5)),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.save_rounded),
            label: const Text('Сохранить настройки',
                style: TextStyle(fontWeight: FontWeight.w900)),
            onPressed: () {
              _persist();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки сохранены!')),
              );
            },
          ),
        ],
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

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: ink)),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 8, 0),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, height: 1.3, fontWeight: FontWeight.w700, color: muted)),
      );
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow(this.value, this.values, this.label, this.onChanged);
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
          selectedColor: purple.withOpacity(.18),
          labelStyle: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: selected ? purple : muted,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? purple : const Color(0xFFE3D8F5),
              width: selected ? 2 : 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile(this.title, this.value, this.onChanged);
  final String title;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
        value: value,
        onChanged: onChanged,
        activeColor: purple,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      );
}
