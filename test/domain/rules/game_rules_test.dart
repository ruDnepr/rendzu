import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/game_rules.dart';

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
  group('GomokuRules', () {
    final rules = const GomokuRules();

    test('победа ровно 5', () {
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0),
      ]);
      final win = rules.checkWin(b, const Point(4, 0));
      expect(win, isNotNull);
      expect(win!.winner, StoneColor.black);
      expect(win.line.stones.length, 5);
    });

    test('победа 6+ (оверлайн = победа в гомоку)', () {
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0), const Point(5, 0),
      ]);
      final win = rules.checkWin(b, const Point(5, 0));
      expect(win, isNotNull);
      expect(win!.winner, StoneColor.black);
    });

    test('нет победы при 4', () {
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0),
      ]);
      expect(rules.checkWin(b, const Point(3, 0)), isNull);
    });

    test('нет запрещённых ходов', () {
      final b = _board(9, [const Point(4, 4)]);
      expect(rules.forbiddenIfPlaced(b, const Point(5, 5), StoneColor.black), isNull);
      expect(rules.forbiddenIfPlaced(b, const Point(5, 5), StoneColor.white), isNull);
      expect(rules.forbiddenMoves(b, StoneColor.black), isEmpty);
    });

    test('ничья при заполненной доске', () {
      // заполняем всю доску 3×3 без победы
      final b = Board(3);
      // расставляем в шахматном порядке, не создавая 5 (доска слишком мала)
      b.place(const Point(0, 0), StoneColor.black);
      b.place(const Point(1, 0), StoneColor.white);
      b.place(const Point(2, 0), StoneColor.black);
      b.place(const Point(0, 1), StoneColor.white);
      b.place(const Point(1, 1), StoneColor.black);
      b.place(const Point(2, 1), StoneColor.white);
      b.place(const Point(0, 2), StoneColor.black);
      b.place(const Point(1, 2), StoneColor.white);
      b.place(const Point(2, 2), StoneColor.black);
      expect(rules.isDraw(b), isTrue);
    });
  });

  group('RenjuRules — чёрные', () {
    final rules = const RenjuRules();

    test('победа чёрных только ровно 5', () {
      final b = _board(15, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0),
      ]);
      final win = rules.checkWin(b, const Point(4, 0));
      expect(win, isNotNull);
      expect(win!.winner, StoneColor.black);
    });

    test('оверлайн НЕ победа для чёрных', () {
      final b = _board(15, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0), const Point(5, 0),
      ]);
      final win = rules.checkWin(b, const Point(5, 0));
      expect(win, isNull, reason: 'Оверлайн не победа для чёрных в рэндзю');
    });

    test('запрещённый ход 3-3', () {
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7),
        const Point(7, 5), const Point(7, 6),
      ]);
      expect(rules.forbiddenIfPlaced(b, const Point(7, 7), StoneColor.black),
          ForbiddenKind.doubleThree);
    });

    test('запрещённый ход 4-4', () {
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7), const Point(8, 7),
        const Point(7, 5), const Point(7, 6), const Point(7, 8),
      ]);
      expect(rules.forbiddenIfPlaced(b, const Point(7, 7), StoneColor.black),
          ForbiddenKind.doubleFour);
    });

    test('запрещённый ход — оверлайн', () {
      final b = _board(15, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(5, 0),
      ]);
      expect(rules.forbiddenIfPlaced(b, const Point(4, 0), StoneColor.black),
          ForbiddenKind.overline);
    });
  });

  group('RenjuRules — белые', () {
    final rules = const RenjuRules();

    test('победа белых 5', () {
      final bw = Board(15);
      for (final p in [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0),
      ]) {
        bw.place(p, StoneColor.white);
      }
      final win = rules.checkWin(bw, const Point(4, 0));
      expect(win, isNotNull);
      expect(win!.winner, StoneColor.white);
    });

    test('победа белых 6+ (оверлайн = победа для белых)', () {
      final bw = Board(15);
      for (final p in [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(4, 0), const Point(5, 0),
      ]) {
        bw.place(p, StoneColor.white);
      }
      final win = rules.checkWin(bw, const Point(5, 0));
      expect(win, isNotNull);
      expect(win!.winner, StoneColor.white);
    });

    test('белые не имеют запрещённых ходов', () {
      final bw = Board(15);
      bw.place(const Point(0, 0), StoneColor.white);
      bw.place(const Point(1, 0), StoneColor.white);
      bw.place(const Point(2, 0), StoneColor.white);
      bw.place(const Point(3, 0), StoneColor.white);
      bw.place(const Point(5, 0), StoneColor.white);
      expect(rules.forbiddenIfPlaced(bw, const Point(4, 0), StoneColor.white), isNull);
      expect(rules.forbiddenMoves(bw, StoneColor.white), isEmpty);
    });
  });

  group('rulesFor', () {
    test('gomoku → GomokuRules', () {
      expect(rulesFor(Ruleset.gomoku).runtimeType.toString(), 'GomokuRules');
    });
    test('renju → RenjuRules', () {
      expect(rulesFor(Ruleset.renju).runtimeType.toString(), 'RenjuRules');
    });
  });
}
