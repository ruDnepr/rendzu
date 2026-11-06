import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/pattern_detector.dart';

/// Вспомогательная функция: ставим чёрные камни в перечисленные точки.
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
  group('PatternDetector.runLengthThrough', () {
    test('одиночный камень — длина 1', () {
      final b = _board(9, [const Point(4, 4)]);
      expect(PatternDetector.runLengthThrough(b, const Point(4, 4), Direction(1, 0)), 1);
    });

    test('горизонтальная серия из 5', () {
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0),
      ]);
      expect(PatternDetector.runLengthThrough(b, const Point(2, 0), Direction(1, 0)), 5);
    });

    test('вертикальная серия из 3', () {
      final b = _board(9, [
        const Point(0, 1), const Point(0, 2), const Point(0, 3),
      ]);
      expect(PatternDetector.runLengthThrough(b, const Point(0, 2), Direction(0, 1)), 3);
    });

    test('диагональная серия из 4', () {
      final b = _board(9, [
        const Point(1, 1), const Point(2, 2), const Point(3, 3), const Point(4, 4),
      ]);
      expect(PatternDetector.runLengthThrough(b, const Point(2, 2), Direction(1, 1)), 4);
    });

    test('прерывается чужим камнем', () {
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
      ], [
        const Point(3, 0),
      ]);
      expect(PatternDetector.runLengthThrough(b, const Point(1, 0), Direction(1, 0)), 3);
    });
  });

  group('PatternDetector.makesFive / makesOverline', () {
    test('makesFive истинно для 5', () {
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0),
      ]);
      expect(PatternDetector.makesFive(b, const Point(2, 0)), isTrue);
      expect(PatternDetector.makesOverline(b, const Point(2, 0)), isFalse);
    });

    test('makesOverline истинно для 6', () {
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0), const Point(5, 0),
      ]);
      expect(PatternDetector.makesFive(b, const Point(2, 0)), isFalse);
      expect(PatternDetector.makesOverline(b, const Point(2, 0)), isTrue);
    });
  });

  group('PatternDetector.fourPatternsThrough', () {
    test('простая четвёрка — 1 четыре', () {
      // _XXXXO — закрытая четвёрка
      final b = _board(9, [
        const Point(1, 0), const Point(2, 0), const Point(3, 0), const Point(4, 0),
      ], [
        const Point(5, 0),
      ]);
      final fours = PatternDetector.fourPatternsThrough(b, const Point(2, 0));
      expect(fours.length, 1);
    });

    test('открытая четвёрка _XXXX_ — 1 четыре (не 2)', () {
      final b = _board(9, [
        const Point(1, 0), const Point(2, 0), const Point(3, 0), const Point(4, 0),
      ]);
      final fours = PatternDetector.fourPatternsThrough(b, const Point(2, 0));
      expect(fours.length, 1);
    });

    test('разбитое двойное-четыре на одной линии — 2 четвёрки', () {
      // X_XXX_X где P в середине XXX
      final b = _board(15, [
        const Point(0, 0), const Point(2, 0), const Point(3, 0),
        const Point(4, 0), const Point(6, 0),
      ]);
      final fours = PatternDetector.fourPatternsThrough(b, const Point(3, 0));
      expect(fours.length, 2);
    });
  });

  group('PatternDetector.openThreePatternsThrough', () {
    test('открытая тройка _XXX_ — есть', () {
      final b = _board(9, [
        const Point(3, 0), const Point(4, 0), const Point(5, 0),
      ]);
      final threes = PatternDetector.openThreePatternsThrough(b, const Point(4, 0));
      expect(threes.length, 1);
    });

    test('закрытая тройка OXXX_ — нет открытой тройки', () {
      final b = _board(9, [
        const Point(3, 0), const Point(4, 0), const Point(5, 0),
      ], [
        const Point(2, 0),
      ]);
      final threes = PatternDetector.openThreePatternsThrough(b, const Point(4, 0));
      // правый конец открыт, но тройку можно достроить до открытой четвёрки
      // только если есть место слева. Здесь слева стоит белое → не открытая.
      expect(threes, isEmpty);
    });
  });

  group('PatternDetector.isOpenFourRun', () {
    test('_XXXX_ — открытая четвёрка', () {
      final b = _board(9, [
        const Point(1, 0), const Point(2, 0), const Point(3, 0), const Point(4, 0),
      ]);
      expect(PatternDetector.isOpenFourRun(b, const Point(2, 0), Direction(1, 0)), isTrue);
    });

    test('OXXXX_ — закрытая четвёрка (не открытая)', () {
      final b = _board(9, [
        const Point(1, 0), const Point(2, 0), const Point(3, 0), const Point(4, 0),
      ], [
        const Point(0, 0),
      ]);
      expect(PatternDetector.isOpenFourRun(b, const Point(2, 0), Direction(1, 0)), isFalse);
    });
  });
}
