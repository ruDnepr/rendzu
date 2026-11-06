import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/game_state.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/pattern_detector.dart';
import 'package:rendzu/presentation/providers/game_provider.dart';
import 'package:rendzu/presentation/widgets/board_widget.dart';

/// Экран игры: доска + HUD + контролы + диалоги победы/предупреждения.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Point? _hintMove;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(gameConfigProvider);
      if (config != null) {
        ref.read(gameControllerProvider.notifier).startGame(config);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cfg = state.config;
    // Вычисляем подсветку паттернов для текущего игрока, если включено.
    var threes = const <List<Point>>[];
    var fours = const <List<Point>>[];
    if (cfg.patternHighlightEnabled && !state.gameOver) {
      final mine = _myPatterns(state.board, state.currentColor);
      threes = mine.threes;
      fours = mine.fours;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${cfg.ruleset.russianName} • ${cfg.boardSize.russianName}',
            style: const TextStyle(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Подсказка',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: state.gameOver
                ? null
                : () {
                    final p = ref.read(gameControllerProvider.notifier).hint();
                    setState(() {
                      _hintMove = p;
                      _showHint = true;
                    });
                    Future<void>.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() => _showHint = false);
                      }
                    });
                  },
          ),
          IconButton(
            tooltip: 'Заново',
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmRestart(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Hud(state: state),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BoardWidget(
                  board: state.board,
                  lastMove: state.lastMove,
                  winningLine: state.winningLine,
                  forbiddenHints: state.forbiddenHints,
                  patternThrees: threes,
                  patternFours: fours,
                  hintMove: _showHint ? _hintMove : null,
                  showForbiddenHints: cfg.hintsEnabled,
                  showPatterns: cfg.patternHighlightEnabled,
                  onTapIntersection: _onTap,
                ),
              ),
            ),
            _Controls(
              canUndo: state.config.mode.isOffline &&
                  state.history.isNotEmpty &&
                  !state.gameOver,
              onUndo: () =>
                  ref.read(gameControllerProvider.notifier).undo(),
              onResign: () => _confirmResign(context),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(Point p) {
    ref.read(gameControllerProvider.notifier).placeStone(p);
    setState(() => _showHint = false);
    // показать предупреждение, если был запрещённый ход
    final s = ref.read(gameControllerProvider);
    if (s?.warning != null && mounted) {
      final msg = s!.warning!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
            backgroundColor: AppColors.coralDark,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(gameControllerProvider.notifier).clearWarning();
      });
    }
    // показать победу/ничью
    if (s != null && s.gameOver && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showEndDialog(s);
      });
    }
  }

  ({List<List<Point>> threes, List<List<Point>> fours}) _myPatterns(
      Board board, StoneColor color) {
    final threes = <List<Point>>[];
    final fours = <List<Point>>[];
    for (final pt in board.occupiedPoints()) {
      if (board.at(pt) != color) continue;
      for (final axis in Direction.axes) {
        if (PatternDetector.isOpenFourRun(board, pt, axis)) {
          // четвёрка
          final pos = PatternDetector.runPositions(board, pt, axis);
          if (!fours.any((l) => _sameSet(l, pos))) fours.add(pos);
        }
        // открытая тройка: серия из 3 с открытыми концами
        final len = PatternDetector.runLengthThrough(board, pt, axis);
        if (len == 3) {
          // проверим открытость (похожая логика)
          final (start, end) = PatternDetector.runBounds(board, pt, axis);
          final before = start.step(axis.opposite);
          final after = end.step(axis);
          final be =
              before.inBounds(board.size) && board.at(before) == null;
          final ae =
              after.inBounds(board.size) && board.at(after) == null;
          if (be && ae) {
            final pos = PatternDetector.runPositions(board, pt, axis);
            if (!threes.any((l) => _sameSet(l, pos))) threes.add(pos);
          }
        }
      }
    }
    return (threes: threes, fours: fours);
  }

  bool _sameSet(List<Point> a, List<Point> b) {
    if (a.length != b.length) return false;
    final sa = {...a};
    return b.every(sa.contains);
  }

  void _confirmRestart(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Начать заново?'),
        content: const Text('Текущая партия будет потеряна.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final cfg = ref.read(gameConfigProvider);
              if (cfg != null) {
                ref.read(gameControllerProvider.notifier).startGame(cfg);
              }
            },
            child: const Text('Заново'),
          ),
        ],
      ),
    );
  }

  void _confirmResign(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сдаться?'),
        content: const Text('Ты проиграешь эту партию.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralDark),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gameControllerProvider.notifier).resign();
            },
            child: const Text('Сдаюсь'),
          ),
        ],
      ),
    );
  }

  void _showEndDialog(GameState s) {
    final winner = s.winner?.winner;
    final cfg = s.config;
    String title;
    String message;
    if (winner == null) {
      title = 'Ничья!';
      message = 'Доска заполнена, никто не собрал пять. Попробуем ещё раз?';
    } else {
      final humanWon = cfg.mode != GameMode.vsComputer ||
          winner == cfg.humanColor;
      if (cfg.mode == GameMode.vsComputer) {
        title = humanWon ? 'Победа! 🎉' : 'Компьютер выиграл';
        message = humanWon
            ? 'Отличная игра! Ты собрал пять в ряд!'
            : 'Не расстраивайся, в следующий раз получится!';
      } else {
        title = 'Победа: ${winner.russianName}! 🎉';
        message = 'Пять в ряд — победа!';
      }
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: 'Baloo2')),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // закрыть диалог
              Navigator.of(context).pop(); // выйти из игры в меню
            },
            child: const Text('В меню'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sky),
            onPressed: () {
              Navigator.pop(ctx);
              final cfg2 = ref.read(gameConfigProvider);
              if (cfg2 != null) {
                ref.read(gameControllerProvider.notifier).startGame(cfg2);
              }
            },
            child: const Text('Ещё раз'),
          ),
        ],
      ),
    );
  }
}

/// Верхний HUD: кто ходит, чей цвет, номер хода.
class _Hud extends StatelessWidget {
  const _Hud({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final current = s.currentColor;
    final isBlack = current == StoneColor.black;
    final cfg = s.config;
    final isVsComputer = cfg.mode == GameMode.vsComputer;
    final humanTurn = !isVsComputer || current == cfg.humanColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _PlayerChip(
            color: StoneColor.black,
            active: isBlack,
            label: _labelFor(StoneColor.black, cfg),
          ),
          const Spacer(),
          Column(
            children: [
              Text('Ход ${s.history.length + (s.gameOver ? 0 : 1)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              if (isVsComputer)
                Text(humanTurn ? 'Твой ход' : 'Думает компьютер…',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      color: humanTurn ? AppColors.grass : AppColors.coral,
                      fontWeight: FontWeight.w700,
                    )),
            ],
          ),
          const Spacer(),
          _PlayerChip(
            color: StoneColor.white,
            active: !isBlack,
            label: _labelFor(StoneColor.white, cfg),
          ),
        ],
      ),
    );
  }

  String _labelFor(StoneColor color, GameConfig cfg) {
    if (cfg.mode == GameMode.vsComputer) {
      return color == cfg.humanColor ? 'Ты' : 'Компьютер';
    }
    return color == StoneColor.black ? 'Игрок 1' : 'Игрок 2';
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.color,
    required this.active,
    required this.label,
  });
  final StoneColor color;
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.sunflower.withOpacity(0.35)
            : AppColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.sunflower : AppColors.textLight,
          width: active ? 2.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                colors: color == StoneColor.black
                    ? const [AppColors.stoneBlackHi, AppColors.stoneBlack]
                    : const [Colors.white, AppColors.stoneWhite],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              )),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.canUndo,
    required this.onUndo,
    required this.onResign,
  });
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onResign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo),
            label: const Text('Отменить'),
          ),
          TextButton.icon(
            onPressed: onResign,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Сдаться'),
            style: TextButton.styleFrom(foregroundColor: AppColors.coralDark),
          ),
        ],
      ),
    );
  }
}
