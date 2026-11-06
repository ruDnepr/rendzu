import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/pattern_detector.dart';
import 'package:rendzu/domain/rules/renju_forbidden_checker.dart';

// ForbiddenKind — часть API правил (возвращается из forbiddenIfPlaced).
export 'package:rendzu/domain/rules/pattern_detector.dart'
    show ForbiddenKind;

/// Интерфейс набора правил: определяет, что является победой, ничьей и (для
/// рэндзю) запрещённым ходом. Реализации — [GomokuRules] и [RenjuRules].
abstract class GameRules {
  const GameRules();

  Ruleset get ruleset;

  /// Проверить победу после хода в [p] (камень уже стоит). Возвращает линию
  /// победы или null.
  WinResult? checkWin(Board board, Point p);

  /// Проверить, является ли ход в [p] (камень цвета [color] ещё не поставлен)
  /// запрещённым. Для гомоку всегда null. Для рэндзю — только для чёрных.
  ForbiddenKind? forbiddenIfPlaced(Board board, Point p, StoneColor color);

  /// Список запрещённых точек для цвета [color] на текущей доске (для подсказок).
  Set<Point> forbiddenMoves(Board board, StoneColor color);

  /// Ничья — доска заполнена и никто не победил.
  bool isDraw(Board board) => board.isFull;

  /// Короткое имя правил.
  String get displayName;
}

/// Гомоку: свободное пять в ряд. Победа — 5 и более подряд (детское упрощение:
/// оверлайн тоже считается победой). Запрещённых ходов нет.
class GomokuRules extends GameRules {
  const GomokuRules();

  @override
  Ruleset get ruleset => Ruleset.gomoku;

  @override
  String get displayName => 'Гомоку';

  @override
  WinResult? checkWin(Board board, Point p) {
    final color = board.at(p);
    if (color == null) return null;
    for (final axis in Direction.axes) {
      final run = PatternDetector.runLengthThrough(board, p, axis);
      if (run >= 5) {
        final stones = PatternDetector.runPositions(board, p, axis);
        return WinResult(
          winner: color,
          line: WinLine(stones, color),
        );
      }
    }
    return null;
  }

  @override
  ForbiddenKind? forbiddenIfPlaced(Board board, Point p, StoneColor color) {
    // В гомоку запрещённых ходов нет.
    return null;
  }

  @override
  Set<Point> forbiddenMoves(Board board, StoneColor color) => {};
}

/// Рэндзю: чёрные имеют запрещённые ходы (оверлайн, 4-4, 3-3). Победа чёрных —
/// только ровно пять; победа белых — пять и более.
class RenjuRules extends GameRules {
  const RenjuRules();

  @override
  Ruleset get ruleset => Ruleset.renju;

  @override
  String get displayName => 'Рэндзю';

  @override
  WinResult? checkWin(Board board, Point p) {
    final color = board.at(p);
    if (color == null) return null;
    for (final axis in Direction.axes) {
      final run = PatternDetector.runLengthThrough(board, p, axis);
      if (color == StoneColor.black) {
        // Чёрные побеждают только ровно пятью.
        if (run == 5) {
          final stones = PatternDetector.runPositions(board, p, axis);
          return WinResult(
            winner: StoneColor.black,
            line: WinLine(stones, StoneColor.black),
          );
        }
        // run >= 6 — оверлайн, НЕ победа для чёрных (запрещено, см. forbidden).
      } else {
        // Белые побеждают пятью и более.
        if (run >= 5) {
          final stones = PatternDetector.runPositions(board, p, axis);
          return WinResult(
            winner: StoneColor.white,
            line: WinLine(stones, StoneColor.white),
          );
        }
      }
    }
    return null;
  }

  @override
  ForbiddenKind? forbiddenIfPlaced(Board board, Point p, StoneColor color) {
    // Запрещены только ходы чёрных.
    if (color != StoneColor.black) return null;
    return RenjuForbiddenChecker.checkCandidate(board, p);
  }

  @override
  Set<Point> forbiddenMoves(Board board, StoneColor color) {
    if (color != StoneColor.black) return {};
    return RenjuForbiddenChecker.forbiddenMoves(board);
  }
}

/// Фабрика правил по набору.
GameRules rulesFor(Ruleset ruleset) {
  switch (ruleset) {
    case Ruleset.gomoku:
      return const GomokuRules();
    case Ruleset.renju:
      return const RenjuRules();
  }
}
