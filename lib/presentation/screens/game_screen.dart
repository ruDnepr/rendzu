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

/// Экран игры: доска + HUD + контролы + диалог победы с указанием ходa.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Point? _hintMove;
  bool _showHint = false;
  bool _dialogShown = false;

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
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(purple.withOpacity(.6)),
            ),
          ),
        ),
      );
    }
    final cfg = state.config;
    var threes = const <List<Point>>[];
    var fours = const <List<Point>>[];
    if (cfg.patternHighlightEnabled && !state.gameOver) {
      final mine = _myPatterns(state.board, state.currentColor);
      threes = mine.threes;
      fours = mine.fours;
    }

    // показать победу/ничью один раз
    if (state.gameOver && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showResult(state);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${cfg.ruleset.russianName} · ${cfg.boardSize.russianName}',
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Подсказка',
            icon: const Icon(Icons.lightbulb_outline_rounded),
            onPressed: state.gameOver
                ? null
                : () {
                    final p =
                        ref.read(gameControllerProvider.notifier).hint();
                    setState(() {
                      _hintMove = p;
                      _showHint = true;
                    });
                    Future<void>.delayed(const Duration(seconds: 3), () {
                      if (mounted) setState(() => _showHint = false);
                    });
                  },
          ),
          IconButton(
            tooltip: 'Заново',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _confirmRestart(context),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
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
                onUndo: () => ref.read(gameControllerProvider.notifier).undo(),
                onResign: () => _confirmResign(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(Point p) {
    ref.read(gameControllerProvider.notifier).placeStone(p);
    setState(() => _showHint = false);
    final s = ref.read(gameControllerProvider);
    if (s?.warning != null && mounted) {
      final msg = s!.warning!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFE27D60),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(gameControllerProvider.notifier).clearWarning();
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
          final pos = PatternDetector.runPositions(board, pt, axis);
          if (!fours.any((l) => _sameSet(l, pos))) fours.add(pos);
        }
        final len = PatternDetector.runLengthThrough(board, pt, axis);
        if (len == 3) {
          final (start, end) = PatternDetector.runBounds(board, pt, axis);
          final before = start.step(axis.opposite);
          final after = end.step(axis);
          final be = before.inBounds(board.size) && board.at(before) == null;
          final ae = after.inBounds(board.size) && board.at(after) == null;
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
    showDianaDialog<bool>(
      context: context,
      title: 'Начать заново?',
      content: const Text('Текущая партия будет потеряна.',
          textAlign: TextAlign.center, style: dialogTextStyle),
      actions: const [
        DianaDialogButton<bool>(label: 'Отмена', value: false),
        DianaDialogButton<bool>(
            label: 'Заново', value: true, primary: true),
      ],
    ).then((ok) {
      if (ok == true) {
        final cfg = ref.read(gameConfigProvider);
        if (cfg != null) {
          setState(() => _dialogShown = false);
          ref.read(gameControllerProvider.notifier).startGame(cfg);
        }
      }
    });
  }

  void _confirmResign(BuildContext context) {
    showDianaDialog<bool>(
      context: context,
      title: 'Сдаться?',
      content: const Text('Ты проиграешь эту партию.',
          textAlign: TextAlign.center, style: dialogTextStyle),
      actions: const [
        DianaDialogButton<bool>(label: 'Отмена', value: false),
        DianaDialogButton<bool>(
            label: 'Сдаюсь', value: true, primary: true),
      ],
    ).then((ok) {
      if (ok == true) {
        ref.read(gameControllerProvider.notifier).resign();
      }
    });
  }

  /// Диалог результата: чётко показывает, каким ходом и кто победил.
  Future<void> _showResult(GameState state) async {
    final winner = state.winner?.winner;
    final cfg = state.config;
    final lastMove = state.lastMove;
    final line = state.winningLine;
    final moveNo = state.history.length;

    String title;
    String message;
    bool calm = false;
    if (winner == null) {
      title = 'Ничья!';
      message = 'Доска заполнена, никто не собрал пять. Попробуем ещё раз?';
      calm = true;
    } else {
      final humanWon =
          cfg.mode != GameMode.vsComputer || winner == cfg.humanColor;
      if (cfg.mode == GameMode.vsComputer) {
        title = humanWon ? 'Ты молодец!' : 'Отличная партия!';
      } else {
        title = '${winner.russianName} победили!';
      }
      // Описание победного хода.
      final direction = _describeDirection(line);
      final pointStr = lastMove != null
          ? 'ходом №$moveNo в клетку (${lastMove.x + 1}, ${lastMove.y + 1})'
          : 'последним ходом';
      if (cfg.mode == GameMode.vsComputer && humanWon) {
        message = 'Ты собрал пять в ряд — $direction, $pointStr. Так держать!';
      } else if (cfg.mode == GameMode.vsComputer && !humanWon) {
        message = 'Компьютер собрал пять в ряд — $direction, $pointStr. '
            'В следующий раз обязательно получится!';
      } else {
        message = '${winner.russianName} собрали пять в ряд — $direction, '
            '$pointStr. Здорово сыграно!';
      }
    }

    final choice = await showDianaDialog<_ResultChoice>(
      context: context,
      title: title,
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Celebration(calm: calm),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center, style: dialogTextStyle),
        ],
      ),
      actions: [
        const DianaDialogButton<_ResultChoice>(
            label: 'Играть снова', value: _ResultChoice.again, primary: true),
        if (state.config.mode.isOffline && state.history.isNotEmpty)
          const DianaDialogButton<_ResultChoice>(
              label: 'Отменить ход', value: _ResultChoice.undo),
        const DianaDialogButton<_ResultChoice>(
            label: 'В меню', value: _ResultChoice.home),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case _ResultChoice.again:
        final cfg2 = ref.read(gameConfigProvider);
        if (cfg2 != null) {
          setState(() => _dialogShown = false);
          ref.read(gameControllerProvider.notifier).startGame(cfg2);
        }
      case _ResultChoice.undo:
        setState(() => _dialogShown = false);
        ref.read(gameControllerProvider.notifier).undo();
      case _ResultChoice.home:
        Navigator.of(context).popUntil((r) => r.settings.name == '/menu');
      case null:
        break;
    }
  }

  /// Человеческое описание направления победной линии.
  String _describeDirection(List<Point> line) {
    if (line.length < 2) return 'пять в ряд';
    final a = line.first;
    final b = line.last;
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    if (dy == 0) return 'по горизонтали';
    if (dx == 0) return 'по вертикали';
    if ((dx > 0 && dy > 0) || (dx < 0 && dy < 0)) return 'по диагонали ↘';
    return 'по диагонали ↗';
  }
}

enum _ResultChoice { again, undo, home }

/// Верхний HUD: кто ходит, цвет, номер хода.
class _Hud extends StatelessWidget {
  const _Hud({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final current = state.currentColor;
    final isBlack = current == StoneColor.black;
    final cfg = state.config;
    final isVsComputer = cfg.mode == GameMode.vsComputer;
    final humanTurn = !isVsComputer || current == cfg.humanColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _PlayerChip(color: StoneColor.black, active: isBlack),
          const Spacer(),
          Column(
            children: [
              Text('Ход ${state.history.length + (state.gameOver ? 0 : 1)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: muted)),
              if (isVsComputer)
                Text(
                  humanTurn ? 'Твой ход' : 'Думает компьютер…',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: humanTurn ? purple : const Color(0xFFE27D60),
                  ),
                ),
            ],
          ),
          const Spacer(),
          _PlayerChip(color: StoneColor.white, active: !isBlack),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.color, required this.active});
  final StoneColor color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? yellow.withOpacity(.30)
            : Colors.white.withOpacity(.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? yellow : const Color(0xFFE3D8F5),
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
                    ? const [stoneBlackHi, stoneBlack]
                    : const [Colors.white, stoneWhite],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            color == StoneColor.black ? 'Чёрные' : 'Белые',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: ink),
          ),
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
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Отменить'),
          ),
          TextButton.icon(
            onPressed: onResign,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Сдаться'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFE27D60)),
          ),
        ],
      ),
    );
  }
}
