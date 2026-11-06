import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/pattern_detector.dart';

// Реэкспортируем ForbiddenKind, чтобы потребителям не нужно было
// отдельно импортировать pattern_detector.
export 'package:rendzu/domain/rules/pattern_detector.dart'
    show ForbiddenKind;

/// Проверщик запрещённых ходов для чёрных в рэндзю.
///
/// Правила (для чёрных):
///   1. Если ход создаёт ровно пять — это победа (исключение, не запрещено),
///      даже если одновременно создаётся оверлайн или другие запрещённые
///      паттерны.
///   2. Оверлайн: ход создаёт 6+ подряд — запрещён.
///   3. Двойное четыре (4-4): ход создаёт две и более четвёрки — запрещён.
///   4. Двойное три (3-3): ход создаёт два и более открытых тройки — запрещён.
///
/// Все проверки выполняются на копии доски с уже поставленным камнем в точке
/// [p]. Цвет камня — чёрный (проверка имеет смысл только для чёрных).
class RenjuForbiddenChecker {
  RenjuForbiddenChecker._();

  /// Проверяет, является ли ход чёрных в точку [p] (камень уже стоит на [b])
  /// запрещённым. Возвращает [ForbiddenKind] или null, если ход разрешён.
  ///
  /// Порядок проверки соответствует приоритету правил:
  /// пять → оверлайн → двойное-четыре → двойное-три.
  static ForbiddenKind? check(Board b, Point p) {
    // 1. Пять? → победа, не запрещено (исключение).
    if (PatternDetector.makesFive(b, p)) {
      return null;
    }
    // 2. Оверлайн (6+).
    if (PatternDetector.makesOverline(b, p)) {
      return ForbiddenKind.overline;
    }
    // 3. Двойное четыре.
    final fours = PatternDetector.fourPatternsThrough(b, p);
    if (fours.length >= 2) {
      return ForbiddenKind.doubleFour;
    }
    // 4. Двойное три.
    final threes = PatternDetector.openThreePatternsThrough(b, p);
    if (threes.length >= 2) {
      return ForbiddenKind.doubleThree;
    }
    return null;
  }

  /// Проверяет запрещённость хода «в точку [p]» относительно доски БЕЗ камня в
  /// [p]. Ставит чёрный камень во временную копию и вызывает [check].
  static ForbiddenKind? checkCandidate(Board board, Point p) {
    if (!p.inBounds(board.size) || board.at(p) != null) return null;
    final copy = board.copy();
    copy.place(p, StoneColor.black);
    return check(copy, p);
  }

  /// Возвращает множество точек, где ход чёрных был бы запрещён. Используется
  /// для подсказок и предупреждений. Рассматриваем только пустые поля рядом с
  /// уже стоящими камнями (радиус 2), чтобы не сканировать всю доску.
  static Set<Point> forbiddenMoves(Board board) {
    final result = <Point>{};
    final candidates = <Point>{};
    for (final stone in board.occupiedPoints()) {
      // радиус 2 вокруг каждого камня
      for (var dx = -2; dx <= 2; dx++) {
        for (var dy = -2; dy <= 2; dy++) {
          final pt = Point(stone.x + dx, stone.y + dy);
          if (pt.inBounds(board.size) && board.at(pt) == null) {
            candidates.add(pt);
          }
        }
      }
    }
    for (final c in candidates) {
      final f = checkCandidate(board, c);
      if (f != null) result.add(c);
    }
    return result;
  }
}
