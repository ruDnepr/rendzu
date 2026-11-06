import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/point.dart';

/// Результат проверки запрещённого хода для чёрных в рэндзю.
enum ForbiddenKind { overline, doubleFour, doubleThree }

extension ForbiddenKindX on ForbiddenKind {
  String get russianName => switch (this) {
        ForbiddenKind.overline => 'Оверлайн (шесть и больше в ряд)',
        ForbiddenKind.doubleFour => 'Двойное четыре (4-4)',
        ForbiddenKind.doubleThree => 'Двойное три (3-3)',
      };

  /// Детское пояснение.
  String get kidExplanation => switch (this) {
        ForbiddenKind.overline =>
          'Такой ход нельзя: получится шесть в ряд. Чёрные побеждают только ровно пятью камнями!',
        ForbiddenKind.doubleFour =>
          'Такой ход нельзя: получится сразу два «четыре». Это запрещено для чёрных.',
        ForbiddenKind.doubleThree =>
          'Такой ход нельзя: получится сразу два «три». Это запрещено для чёрных.',
      };
}

/// Линия победы — пять камней подряд.
class WinLine {
  const WinLine(this.stones, this.color);

  final List<Point> stones;
  final StoneColor color;

  @override
  String toString() => 'Win($color, ${stones.length}: $stones)';
}

/// Результат проверки хода на победу.
class WinResult {
  const WinResult({required this.winner, required this.line});
  final StoneColor winner;
  final WinLine line;

  @override
  String toString() => 'WinResult($winner, ${line.stones.length})';
}

/// Анализатор паттернов на доске: серии камней, четвёрки, тройки, открытые
/// четвёрки. Все функции предполагают, что камень уже поставлен в точке [p].
///
/// Используется как гомоку-правилами, так и рэндзю-проверщиком запрещённых
/// ходов. Чёткие определения:
///   — «пять»: ровно 5 подряд камней одного цвета.
///   — «оверлайн»: 6 и более подряд.
///   — «четыре»: 4 камня, к которым можно добавить один и получить ровно пять
///     (хотя бы одним способом). Считаем различные четвёрки как различные
///     множества из 4 позиций (это корректно учитывает двойное-четыре на одной
///     линии и открытую четвёрку как одну).
///   — «открытая четвёрка» (_XXXX_): 4 подряд с обеих сторон пусто.
///   — «открытое три»: 3 камня, к которым можно добавить один и получить
///     открытую четвёрку.
class PatternDetector {
  PatternDetector._();

  /// Длина максимальной непрерывной серии цвета [b.at(p)] через точку [p]
  /// вдоль оси [axis] (в обе стороны).
  static int runLengthThrough(Board b, Point p, Direction axis) {
    final color = b.at(p);
    if (color == null) return 0;
    var len = 1;
    var cur = p.step(axis);
    while (b.at(cur) == color) {
      len++;
      cur = cur.step(axis);
    }
    cur = p.step(axis.opposite);
    while (b.at(cur) == color) {
      len++;
      cur = cur.step(axis.opposite);
    }
    return len;
  }

  /// Границы непрерывной серии (start, end) цвета в [p] вдоль оси [axis].
  static (Point, Point) runBounds(Board b, Point p, Direction axis) {
    final color = b.at(p)!;
    var start = p;
    var end = p;
    var cur = p.step(axis);
    while (b.at(cur) == color) {
      end = cur;
      cur = cur.step(axis);
    }
    cur = p.step(axis.opposite);
    while (b.at(cur) == color) {
      start = cur;
      cur = cur.step(axis.opposite);
    }
    return (start, end);
  }

  /// Позиции непрерывной серии цвета в [p] вдоль оси [axis] (включая [p]).
  static List<Point> runPositions(Board b, Point p, Direction axis) {
    final color = b.at(p);
    if (color == null) return const [];
    final (start, end) = runBounds(b, p, axis);
    final out = <Point>[];
    var cur = start;
    out.add(cur);
    while (cur != end) {
      cur = cur.step(axis);
      out.add(cur);
    }
    return out;
  }

  /// Максимальная длина серии через [p] по всем осям.
  static int maxRunThrough(Board b, Point p) {
    var m = 0;
    for (final axis in Direction.axes) {
      final r = runLengthThrough(b, p, axis);
      if (r > m) m = r;
    }
    return m;
  }

  /// Есть ли ровно пять через [p] хотя бы по одной оси?
  static bool makesFive(Board b, Point p) {
    for (final axis in Direction.axes) {
      if (runLengthThrough(b, p, axis) == 5) return true;
    }
    return false;
  }

  /// Есть ли оверлайн (6+) через [p] хотя бы по одной оси?
  static bool makesOverline(Board b, Point p) {
    for (final axis in Direction.axes) {
      if (runLengthThrough(b, p, axis) >= 6) return true;
    }
    return false;
  }

  /// Является ли серия через [p] вдоль [axis] открытой четвёркой:
  /// ровно 4 подряд, и обе соседние клетки пустые.
  static bool isOpenFourRun(Board b, Point p, Direction axis) {
    final color = b.at(p);
    if (color == null) return false;
    final len = runLengthThrough(b, p, axis);
    if (len != 4) return false;
    final (start, end) = runBounds(b, p, axis);
    final before = start.step(axis.opposite);
    final after = end.step(axis);
    final beforeEmpty =
        before.inBounds(b.size) && b.at(before) == null;
    final afterEmpty = after.inBounds(b.size) && b.at(after) == null;
    return beforeEmpty && afterEmpty;
  }

  /// Различные «четвёрки» (множества по 4 позиции одного цвета, включая [p]),
  /// которые можно дополнить одним камнем до ровно пяти. Цвет = [b.at(p)].
  ///
  /// Для каждого пустого поля [e] рядом с [p] вдоль каждой оси симулируем
  /// постановку камня того же цвета и проверяем, образовалась ли ровно пять
  /// через [p]. Четвёрка = пять минус [e]. Дедуплицируем по ключу позиций,
  /// поэтому открытая четвёрка `_XXXX_` считается за одну.
  static List<List<Point>> fourPatternsThrough(Board b, Point p) {
    final color = b.at(p);
    if (color == null) return const [];
    final seen = <String>{};
    final fours = <List<Point>>[];
    for (final axis in Direction.axes) {
      for (var i = -4; i <= 4; i++) {
        if (i == 0) continue;
        final e = Point(p.x + axis.dx * i, p.y + axis.dy * i);
        if (!e.inBounds(b.size) || b.at(e) != null) continue;
        b.place(e, color);
        final run = runLengthThrough(b, p, axis);
        if (run == 5) {
          final positions = runPositions(b, p, axis);
          // five = positions; four = positions minus e
          final four = positions.where((q) => q != e).toList()
            ..sort((a, b) => a.compareTo(b));
          final key = four.map((q) => '${q.x},${q.y}').join('|');
          if (seen.add(key)) fours.add(four);
        }
        b.remove(e);
      }
    }
    return fours;
  }

  /// Различные «открытые тройки» (множества по 3 позиции одного цвета, включая
  /// [p]), которые можно дополнить одним камнем до открытой четвёрки.
  static List<List<Point>> openThreePatternsThrough(Board b, Point p) {
    final color = b.at(p);
    if (color == null) return const [];
    final seen = <String>{};
    final threes = <List<Point>>[];
    for (final axis in Direction.axes) {
      for (var i = -4; i <= 4; i++) {
        if (i == 0) continue;
        final e = Point(p.x + axis.dx * i, p.y + axis.dy * i);
        if (!e.inBounds(b.size) || b.at(e) != null) continue;
        b.place(e, color);
        if (isOpenFourRun(b, p, axis)) {
          final four = runPositions(b, p, axis); // ровно 4 позиции
          final three = four.where((q) => q != e).toList()
            ..sort((a, b) => a.compareTo(b));
          final key = three.map((q) => '${q.x},${q.y}').join('|');
          if (seen.add(key)) threes.add(three);
        }
        b.remove(e);
      }
    }
    return threes;
  }
}
