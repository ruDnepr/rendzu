import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/move.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/game_rules.dart';
import 'package:rendzu/domain/rules/pattern_detector.dart';
import 'package:rendzu/domain/rules/renju_forbidden_checker.dart';

/// Неизменяемое состояние партии.
///
/// Хранит доску, историю ходов, чей сейчас ход, победителя и transient-поле
/// предупреждения о запрещённом ходе. Все операции возвращают новое состояние.
class GameState {
  GameState({
    required this.config,
    required this.rules,
    Board? board,
    StoneColor? currentColor,
    List<Move>? history,
    this.winner,
    this.gameOver = false,
    this.winningLine = const [],
    this.lastMove,
    this.warning,
    this.lastMoveForbidden = false,
    this.forbiddenHints = const {},
  })  : board = board ?? Board(config.boardDimension),
        currentColor = currentColor ?? StoneColor.black,
        history = history ?? const [];

  final GameConfig config;
  final GameRules rules;
  final Board board;
  final StoneColor currentColor;
  final List<Move> history;
  final WinResult? winner;
  final bool gameOver;
  final List<Point> winningLine;
  final Point? lastMove;
  final String? warning;
  final bool lastMoveForbidden;
  final Set<Point> forbiddenHints;

  bool get isRenju => rules.ruleset == Ruleset.renju;
  bool get isBlackTurn => currentColor == StoneColor.black;
  bool get hasWinner => winner != null;

  /// Чей следующий ход (после текущего). null если игра окончена.
  StoneColor? get nextColor =>
      gameOver ? null : currentColor.opponent;

  GameState copyWith({
    Board? board,
    StoneColor? currentColor,
    List<Move>? history,
    WinResult? winner,
    bool? gameOver,
    List<Point>? winningLine,
    Point? lastMove,
    String? warning,
    bool? lastMoveForbidden,
    Set<Point>? forbiddenHints,
  }) =>
      GameState(
        config: config,
        rules: rules,
        board: board ?? this.board,
        currentColor: currentColor ?? this.currentColor,
        history: history ?? this.history,
        winner: winner ?? this.winner,
        gameOver: gameOver ?? this.gameOver,
        winningLine: winningLine ?? this.winningLine,
        lastMove: lastMove ?? this.lastMove,
        warning: warning,
        lastMoveForbidden: lastMoveForbidden ?? false,
        forbiddenHints: forbiddenHints ?? this.forbiddenHints,
      );

  GameState clearWarning() => copyWith();

  /// Применить ход в точку [p] от текущего игрока.
  ///
  /// Поведение для запрещённого хода (рэндзю, чёрные): ход ОТКЛОНЯЕТСЯ, доска
  /// не меняется, в поле [warning] кладётся детское пояснение. Это безопасный
  /// детский режим (вместо немедленного поражения) и он же используется в сети.
  MoveResult makeMove(Point p) {
    if (gameOver) {
      return MoveResult.forbidden(this, 'Игра уже окончена.');
    }
    if (!p.inBounds(board.size) || board.at(p) != null) {
      return MoveResult.forbidden(this, 'Эта клетка уже занята.');
    }

    // Проверка запрещённого хода (только рэндзю, только чёрные).
    final forbidden = rules.forbiddenIfPlaced(board, p, currentColor);
    if (forbidden != null) {
      return MoveResult.forbidden(
        copyWith(warning: forbidden.kidExplanation),
        forbidden.kidExplanation,
        kind: forbidden,
      );
    }

    final newBoard = board.copy();
    newBoard.place(p, currentColor);

    final win = rules.checkWin(newBoard, p);
    final move = Move(
      point: p,
      color: currentColor,
      number: history.length + 1,
    );
    final newHistory = [...history, move];

    if (win != null) {
      return MoveResult(
        state: copyWith(
          board: newBoard,
          history: newHistory,
          winner: win,
          gameOver: true,
          winningLine: win.line.stones,
          lastMove: p,
          warning: null,
          forbiddenHints: const {},
        ),
        outcome: MoveOutcome.win,
      );
    }

    if (rules.isDraw(newBoard)) {
      return MoveResult(
        state: copyWith(
          board: newBoard,
          history: newHistory,
          gameOver: true,
          lastMove: p,
          warning: null,
          forbiddenHints: const {},
        ),
        outcome: MoveOutcome.draw,
      );
    }

    // Подсказки запрещённых ходов для следующего хода (если следующий — чёрные
    // в рэндзю и включены подсказки).
    final nextColor = currentColor.opponent;
    Set<Point> hints = const {};
    if (config.hintsEnabled &&
        rules.ruleset == Ruleset.renju &&
        nextColor == StoneColor.black) {
      hints = RenjuForbiddenChecker.forbiddenMoves(newBoard);
    }

    return MoveResult(
      state: copyWith(
        board: newBoard,
        history: newHistory,
        currentColor: nextColor,
        lastMove: p,
        warning: null,
        forbiddenHints: hints,
      ),
      outcome: MoveOutcome.normal,
    );
  }

  /// Отмена последнего хода (офлайн). Возвращает новое состояние или null,
  /// если отменять нечего.
  GameState? undo() {
    if (history.isEmpty || gameOver) return null;
    final last = history.last;
    final newBoard = board.copy();
    newBoard.remove(last.point);
    final newHistory = history.sublist(0, history.length - 1);
    final prevColor = last.color;
    // пересчитать подсказки запрещённых
    Set<Point> hints = const {};
    if (config.hintsEnabled &&
        rules.ruleset == Ruleset.renju &&
        prevColor == StoneColor.black) {
      hints = RenjuForbiddenChecker.forbiddenMoves(newBoard);
    }
    return copyWith(
      board: newBoard,
      history: newHistory,
      currentColor: prevColor,
      winner: null,
      gameOver: false,
      winningLine: const [],
      lastMove: newHistory.isEmpty ? null : newHistory.last.point,
      warning: null,
      forbiddenHints: hints,
    );
  }

  /// Подсказка «хороший ход»: простая эвристика — вернуть точку рядом с
  /// последним ходом соперника или центр, если доска пуста. Реальный ИИ живёт
  /// в [RenjuAI]; этот метод — быстрый fallback для кнопки «Подсказка».
  Point? hintPoint() {
    if (history.isEmpty) {
      final c = board.size ~/ 2;
      return Point(c, c);
    }
    // ищем пустую точку рядом с последним ходом, образующую максимум своих
    final me = currentColor;
    Point? best;
    var bestScore = -1;
    for (final stone in board.occupiedPoints()) {
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;
          final pt = Point(stone.x + dx, stone.y + dy);
          if (!pt.inBounds(board.size) || board.at(pt) != null) continue;
          final copy = board.copy();
          copy.place(pt, me);
          final score = PatternDetector.maxRunThrough(copy, pt);
          if (score > bestScore) {
            bestScore = score;
            best = pt;
          }
        }
      }
    }
    return best;
  }

  /// Сдаться (поражение текущего игрока).
  GameState resign() {
    if (gameOver) return this;
    return copyWith(
      gameOver: true,
      winner: WinResult(
        winner: currentColor.opponent,
        line: const WinLine(const [], StoneColor.black),
      ),
      warning: null,
    );
  }
}

/// Результат применения хода.
class MoveResult {
  const MoveResult({required this.state, required this.outcome, this.message});
  final GameState state;
  final MoveOutcome outcome;
  final String? message;

  factory MoveResult.forbidden(GameState state, String message,
      {ForbiddenKind? kind}) {
    return MoveResult(
      state: state,
      outcome: MoveOutcome.forbidden,
      message: message,
    );
  }
}
