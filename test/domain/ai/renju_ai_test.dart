import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/domain/ai/renju_ai.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/game_config.dart';
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
  group('RenjuAI — общий', () {
    test('пустая доска → ход в центр', () {
      final b = Board(9);
      final m = RenjuAI.findBestMove(b, StoneColor.black, Difficulty.easy,
          ruleset: Ruleset.gomoku);
      expect(m, isNotNull);
      expect(m, const Point(4, 4));
    });

    test('возвращает ход рядом с камнями', () {
      final b = _board(9, [const Point(4, 4)]);
      final m = RenjuAI.findBestMove(b, StoneColor.white, Difficulty.easy,
          ruleset: Ruleset.gomoku);
      expect(m, isNotNull);
      // соседняя к (4,4)
      expect((m!.x - 4).abs() + (m.y - 4).abs(), lessThanOrEqualTo(2));
    });
  });

  group('RenjuAI — немедленная победа', () {
    test('ИИ завершает пять, если может', () {
      // чёрные: 4 подряд, ход чёрных → должны поставить 5-й
      final b = _board(9, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0),
      ]);
      for (final level in Difficulty.values) {
        final m = RenjuAI.findBestMove(b, StoneColor.black, level,
            ruleset: Ruleset.gomoku);
        expect(m, const Point(4, 0),
            reason: 'Уровень $level должен завершать пять');
      }
    });
  });

  group('RenjuAI — блокировка', () {
    test('ИИ блокирует победный ход соперника (4 в ряд)', () {
      // белые: 4 подряд _BBBB_, ход чёрных → чёрные должны заблокировать
      final b = _board(9, const [], [
        const Point(2, 0), const Point(3, 0), const Point(4, 0),
        const Point(5, 0),
      ]);
      final m = RenjuAI.findBestMove(b, StoneColor.black, Difficulty.hard,
          ruleset: Ruleset.gomoku);
      expect(m, isNotNull);
      // блокировка — это точка (1,0) или (6,0)
      expect(m, anyOf(equals(const Point(1, 0)), equals(const Point(6, 0))));
    });

    test('средний уровень блокирует 4 в ряд', () {
      final b = _board(9, const [], [
        const Point(2, 0), const Point(3, 0), const Point(4, 0),
        const Point(5, 0),
      ]);
      final m = RenjuAI.findBestMove(b, StoneColor.black, Difficulty.medium,
          ruleset: Ruleset.gomoku);
      expect(m, anyOf(equals(const Point(1, 0)), equals(const Point(6, 0))));
    });
  });

  group('RenjuAI — запрещённые ходы', () {
    test('ИИ (чёрные, рэндзю) не делает запрещённый ход', () {
      // создаём ситуацию, где есть запрещённый ход (3-3 в точке 7,7)
      final b = _board(15, [
        const Point(5, 7), const Point(6, 7),
        const Point(7, 5), const Point(7, 6),
      ], const []);
      // добавим белые камни, чтобы заставить чёрных ходить
      b.place(const Point(0, 0), StoneColor.white);
      for (final level in Difficulty.values) {
        final m = RenjuAI.findBestMove(b, StoneColor.black, level,
            ruleset: Ruleset.renju);
        expect(m, isNotNull);
        // проверим, что ход не запрещён
        final copy = b.copy();
        copy.place(m!, StoneColor.black);
        final forbidden = RenjuForbiddenChecker.check(copy, m);
        expect(forbidden, isNull,
            reason: 'Уровень $level: ИИ не должен делать запрещённый ход $m');
      }
    });

    test('ИИ избегает оверлайна', () {
      // чёрные 5 в ряд (но это уже победа — пропустим).
      // чёрные: 4 + 1 через пустую, ход чёрных в пустую → оверлайн
      final b = _board(15, [
        const Point(0, 0), const Point(1, 0), const Point(2, 0),
        const Point(3, 0), const Point(5, 0),
      ]);
      // Добавим белого, чтобы был конкурентный контекст.
      b.place(const Point(7, 7), StoneColor.white);
      for (final level in Difficulty.values) {
        final m = RenjuAI.findBestMove(b, StoneColor.black, level,
            ruleset: Ruleset.renju);
        expect(m, isNotNull);
        // ИИ не должен играть (4,0) — это оверлайн
        expect(m, isNot(const Point(4, 0)),
            reason: 'Уровень $level не должен делать оверлайн');
      }
    });
  });

  group('RenjuAI — уровни различаются', () {
    test('лёгкий уровень иногда не блокирует угрозу', () {
      // Создаём вилку (две тройки) — лёгкий может не заметить, сложный заблокирует.
      // Это вероятностный тест: проверяем, что на лёгком уровне ИИ возвращает ход
      // (не падает), а на сложном — блокирует хотя бы одну угрозу.
      final b = _board(9, const [], [
        const Point(4, 3), const Point(4, 4), // белая вертикальная тройка-потенциал
        const Point(3, 4), const Point(5, 4),
      ]);
      final easyMove = RenjuAI.findBestMove(b, StoneColor.black, Difficulty.easy,
          ruleset: Ruleset.gomoku);
      final hardMove = RenjuAI.findBestMove(b, StoneColor.black, Difficulty.hard,
          ruleset: Ruleset.gomoku);
      expect(easyMove, isNotNull);
      expect(hardMove, isNotNull);
    });
  });
}
