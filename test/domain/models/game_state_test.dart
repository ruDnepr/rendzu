import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/game_state.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/game_rules.dart';

GameState _newState(Ruleset ruleset, {int size = 9}) {
  final cfg = GameConfig(
    ruleset: ruleset,
    boardSize: size == 9 ? BoardSize.small9 : BoardSize.standard15,
    mode: GameMode.localTwoPlayers,
    hintsEnabled: true,
  );
  return GameState(config: cfg, rules: rulesFor(ruleset));
}

void main() {
  group('GameState — базовое', () {
    test('начальное состояние: чёрные ходят, доска пуста', () {
      final s = _newState(Ruleset.gomoku);
      expect(s.currentColor, StoneColor.black);
      expect(s.board.isEmpty, isTrue);
      expect(s.gameOver, isFalse);
      expect(s.history, isEmpty);
    });

    test('ход ставит камень и передаёт очередь', () {
      final s = _newState(Ruleset.gomoku);
      final r = s.makeMove(const Point(4, 4));
      expect(r.outcome, MoveOutcome.normal);
      expect(r.state.board.at(const Point(4, 4)), StoneColor.black);
      expect(r.state.currentColor, StoneColor.white);
      expect(r.state.history.length, 1);
      expect(r.state.lastMove, const Point(4, 4));
    });

    test('ход в занятую клетку отклоняется', () {
      final s = _newState(Ruleset.gomoku);
      final s2 = s.makeMove(const Point(4, 4)).state;
      // повторный ход в ту же точку — отклоняется
      final r2 = s2.makeMove(const Point(4, 4));
      expect(r2.outcome, MoveOutcome.forbidden);
    });
  });

  group('GameState — победа', () {
    test('гомоку: пять в ряд → победа', () {
      var s = _newState(Ruleset.gomoku, size: 9);
      // чёрные: 4 в ряд, белые где-то в стороне
      s = s.makeMove(const Point(0, 0)).state; // ч
      s = s.makeMove(const Point(8, 8)).state; // б
      s = s.makeMove(const Point(1, 0)).state; // ч
      s = s.makeMove(const Point(7, 7)).state; // б
      s = s.makeMove(const Point(2, 0)).state; // ч
      s = s.makeMove(const Point(6, 6)).state; // б
      s = s.makeMove(const Point(3, 0)).state; // ч
      s = s.makeMove(const Point(5, 5)).state; // б
      final r = s.makeMove(const Point(4, 0)); // ч — пять!
      expect(r.outcome, MoveOutcome.win);
      expect(r.state.gameOver, isTrue);
      expect(r.state.winner!.winner, StoneColor.black);
      expect(r.state.winningLine.length, 5);
    });
  });

  group('GameState — запрещённый ход отклоняется (рэндзю)', () {
    test('3-3 отклоняется, доска не меняется', () {
      final cfg = GameConfig(
        ruleset: Ruleset.renju,
        boardSize: BoardSize.standard15,
        mode: GameMode.localTwoPlayers,
        hintsEnabled: true,
      );
      var s = GameState(config: cfg, rules: rulesFor(Ruleset.renju));
      // чёрные ставят камни для подготовки 3-3 в (7,7)
      s = s.makeMove(const Point(5, 7)).state; // ч
      s = s.makeMove(const Point(0, 0)).state; // б
      s = s.makeMove(const Point(6, 7)).state; // ч
      s = s.makeMove(const Point(0, 1)).state; // б
      s = s.makeMove(const Point(7, 5)).state; // ч
      s = s.makeMove(const Point(0, 2)).state; // б
      s = s.makeMove(const Point(7, 6)).state; // ч
      s = s.makeMove(const Point(0, 3)).state; // б
      // теперь ход чёрных, и (7,7) — запрещённый (3-3)
      final r = s.makeMove(const Point(7, 7));
      expect(r.outcome, MoveOutcome.forbidden);
      expect(r.state.board.at(const Point(7, 7)), isNull,
          reason: 'Запрещённый ход не должен ставиться на доску');
      expect(r.state.warning, isNotNull);
    });
  });

  group('GameState — отмена хода', () {
    test('undo убирает последний камень', () {
      var s = _newState(Ruleset.gomoku);
      s = s.makeMove(const Point(4, 4)).state;
      expect(s.board.at(const Point(4, 4)), StoneColor.black);
      final undone = s.undo();
      expect(undone, isNotNull);
      expect(undone!.board.at(const Point(4, 4)), isNull);
      expect(undone.history, isEmpty);
    });

    test('undo на пустой доске → null', () {
      final s = _newState(Ruleset.gomoku);
      expect(s.undo(), isNull);
    });
  });

  group('GameState — подсказка', () {
    test('hintPoint возвращает центр на пустой доске', () {
      final s = _newState(Ruleset.gomoku);
      expect(s.hintPoint(), const Point(4, 4));
    });

    test('hintPoint возвращает точку рядом с камнями', () {
      var s = _newState(Ruleset.gomoku);
      s = s.makeMove(const Point(4, 4)).state;
      final h = s.hintPoint();
      expect(h, isNotNull);
      expect((h!.x - 4).abs() + (h.y - 4).abs(), lessThanOrEqualTo(2));
    });
  });

  group('GameState — сдача', () {
    test('resign отдаёт победу сопернику', () {
      var s = _newState(Ruleset.gomoku);
      s = s.makeMove(const Point(4, 4)).state; // чёрные сходили
      // теперь белые, сдадутся
      final r = s.resign();
      expect(r.gameOver, isTrue);
      expect(r.winner!.winner, StoneColor.black,
          reason: 'Сдаются белые — побеждают чёрные');
    });
  });
}
