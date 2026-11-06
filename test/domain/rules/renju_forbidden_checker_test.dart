import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/renju_forbidden_checker.dart';

Board _board(int size, List<Point> black, [List<Point> white = const []]) {
  final b = Board(size);
  for (final p in black) {
    b.place(p, StoneColor.black);
  }
  for (final p in white) {
    b.place(p, StoneColor.white);
  }
  return b;
}

void main() {
  group('RenjuForbiddenChecker — оверлайн', () {
    test('ход, создающий 6 в ряд — оверлайн', () {
      // чёрные: 4 подряд + 1 через пустую → ход в пустую даёт 6
      final b = _board(15, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(5, 0),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(4, 0));
      expect(f, ForbiddenKind.overline);
    });

    test('ход, создающий 7 в ряд — оверлайн', () {
      final b = _board(15, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(5, 0), const Point(6, 0),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(4, 0));
      expect(f, ForbiddenKind.overline);
    });
  });

  group('RenjuForbiddenChecker — двойное три (3-3)', () {
    test('ход создаёт два открытых три — 3-3', () {
      // P=(7,7). Горизонталь: (5,7),(6,7) → после P(7,7) _XXX_ открытое.
      // Вертикаль: (7,5),(7,6) → после P(7,7) _XXX_ открытое.
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7),
        const Point(7, 5), const Point(7, 6),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(7, 7));
      expect(f, ForbiddenKind.doubleThree);
    });

    test('одно открытое три — не запрещено', () {
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(7, 7));
      expect(f, isNull);
    });
  });

  group('RenjuForbiddenChecker — двойное четыре (4-4)', () {
    test('ход создаёт две четвёрки — 4-4', () {
      // P=(7,7). Горизонталь: (5,7),(6,7),(8,7) → после P четыре XXXX.
      // Вертикаль: (7,5),(7,6),(7,8) → после P четыре XXXX.
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7), const Point(8, 7),
        const Point(7, 5), const Point(7, 6), const Point(7, 8),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(7, 7));
      expect(f, ForbiddenKind.doubleFour);
    });

    test('одна четвёрка — не запрещено', () {
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7), const Point(8, 7),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(7, 7));
      expect(f, isNull);
    });
  });

  group('RenjuForbiddenChecker — исключение (пять перекрывает запрет)', () {
    test('ход создаёт ровно пять И оверлайн — победа, не запрещено', () {
      // P=(7,7). Вертикаль: (7,3),(7,4),(7,5),(7,6) → после P пять по вертикали.
      // Диагональ ↘: (3,3),(4,4),(5,5),(6,6),(8,8) → после P шесть по диагонали.
      final b = _board(15, [
        const Point(7, 3), const Point(7, 4), const Point(7, 5), const Point(7, 6),
        const Point(3, 3), const Point(4, 4), const Point(5, 5),
        const Point(6, 6), const Point(8, 8),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(7, 7));
      expect(f, isNull, reason: 'Пять перекрывает оверлайн — это победа');
    });

    test('ход создаёт пять И двойное-три — победа, не запрещено', () {
      // P=(7,7). Вертикаль: (7,3),(7,4),(7,5),(7,6) → пять по вертикали.
      // Горизонталь: (5,7),(6,7) → открытое три.
      // Диагональ ↗: (5,9),(6,8) → открытое три.
      final b = _board(15, [
        const Point(7, 3), const Point(7, 4), const Point(7, 5), const Point(7, 6),
        const Point(5, 7), const Point(6, 7),
        const Point(5, 9), const Point(6, 8),
      ]);
      final f = RenjuForbiddenChecker.checkCandidate(b, const Point(7, 7));
      expect(f, isNull, reason: 'Пять перекрывает двойное-три — победа');
    });
  });

  group('RenjuForbiddenChecker.forbiddenMoves', () {
    test('возвращает пустое множество на пустой доске', () {
      final b = Board(9);
      expect(RenjuForbiddenChecker.forbiddenMoves(b), isEmpty);
    });

    test('находит запрещённый ход рядом с камнями', () {
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7),
        const Point(7, 5), const Point(7, 6),
      ]);
      final moves = RenjuForbiddenChecker.forbiddenMoves(b);
      expect(moves, contains(const Point(7, 7)));
    });
  });
}
