import 'dart:math' as math;

import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/game_config.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/domain/rules/pattern_detector.dart';
import 'package:rendzu/domain/rules/renju_forbidden_checker.dart';

/// Эвристическая оценка позиции для цвета [color].
///
/// Сумма ценностей паттернов: пять → победа, открытая четвёрка, четвёрка,
/// открытое три, тройка, двойка. Возвращает крупное число при победе.
class AiEvaluator {
  AiEvaluator._();

  // Веса паттернов.
  static const int fiveScore = 1000000;
  static const int openFourScore = 100000;
  static const int fourScore = 10000;
  static const int openThreeScore = 5000;
  static const int closedThreeScore = 500;
  static const int openTwoScore = 100;
  static const int closedTwoScore = 30;
  static const int oneScore = 5;

  /// Оценка доски с точки зрения цвета [color] (положительное — хорошо для
  /// [color]). Учитывает атаку [color] и защиту (минус атака соперника).
  static int evaluate(Board board, StoneColor color) {
    final me = scoreFor(board, color);
    final opp = scoreFor(board, color.opponent);
    return me - opp;
  }

  /// Суммарная ценность паттернов цвета [color] на доске.
  static int scoreFor(Board board, StoneColor color) {
    var score = 0;
    // Сканируем каждую линию каждой оси один раз.
    for (final axis in Direction.axes) {
      score += _scoreAxis(board, color, axis);
    }
    return score;
  }

  /// Оценка одной оси: проходим по всем линиям вдоль [axis] и считаем
  /// паттерны цвета [color].
  static int _scoreAxis(Board board, StoneColor color, Direction axis) {
    var total = 0;
    final size = board.size;
    // Определяем «стартовые» точки — те, у которых нет соседа сзади по оси
    // (чтобы каждая линия сканировалась один раз).
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final p = Point(x, y);
        final before = Point(x - axis.dx, y - axis.dy);
        if (before.inBounds(size)) continue; // не старт линии
        total += _scoreLine(board, color, axis, p);
      }
    }
    return total;
  }

  /// Оценка одной линии начиная со стартовой точки [start] вдоль [axis].
  static int _scoreLine(
      Board board, StoneColor color, Direction axis, Point start) {
    final size = board.size;
    // Соберём «окна» длиной 6 вдоль линии и оценим.
    final cells = <StoneColor?>[];
    var cur = start;
    while (cur.inBounds(size)) {
      cells.add(board.at(cur));
      cur = cur.step(axis);
    }
    if (cells.length < 5) return 0;

    var score = 0;
    // Скользящее окно длиной 6: оцениваем паттерны.
    for (var i = 0; i <= cells.length - 5; i++) {
      score += _scoreWindow(cells.sublist(i, math.min(i + 6, cells.length)),
          color, i, start, axis);
    }
    return score;
  }

  /// Оценка окна (до 6 клеток).
  static int _scoreWindow(
    List<StoneColor?> window,
    StoneColor color,
    int startIdx,
    Point lineStart,
    Direction axis,
  ) {
    final opp = color.opponent;
    var own = 0;
    var oppCount = 0;
    for (final c in window) {
      if (c == color) {
        own++;
      } else if (c == opp) {
        oppCount++;
      }
    }
    if (oppCount > 0 && own > 0) return 0; // смешанное окно — нет паттерна
    if (own == 0) return 0;

    // Считаем длину максимальной серии своих в окне и открытость концов.
    switch (own) {
      case 5:
        return fiveScore;
      case 4:
        // открытая четвёрка или четвёрка
        if (_isOpen(window, color)) return openFourScore;
        return fourScore;
      case 3:
        if (_isOpen(window, color)) return openThreeScore;
        return closedThreeScore;
      case 2:
        if (_isOpen(window, color)) return openTwoScore;
        return closedTwoScore;
      default:
        return oneScore;
    }
  }

  /// Открыт ли паттерн (оба конца окна пустые для серии внутри).
  static bool _isOpen(List<StoneColor?> window, StoneColor color) {
    if (window.length < 2) return false;
    // ищем первую и последнюю позицию своего камня
    int? first;
    var last = -1;
    for (var i = 0; i < window.length; i++) {
      if (window[i] == color) {
        first ??= i;
        last = i;
      }
    }
    if (first == null) return false;
    final before = first > 0 ? window[first - 1] : StoneColor.white;
    final after =
        last < window.length - 1 ? window[last + 1] : StoneColor.white;
    return before == null && after == null;
  }
}

/// Кандидат на ход с быстрой оценкой.
class _Candidate {
  _Candidate(this.point, this.score);
  final Point point;
  final int score;
}

/// ИИ для рэндзю/гомоку. Три уровня сложности.
///
///  - easy:   жадная эвристика глубины 1, с долей случайности, иногда
///             «не замечает» неочевидную угрозу, чтобы ребёнок мог выиграть.
///  - medium: жадная эвристика с учётом блокировки, глубина 2.
///  - hard:   минимакс с альфа-бета, глубина 4, лимит кандидатов, не делает
///             запрещённых ходов (если играет чёрными в рэндзю).
class RenjuAI {
  RenjuAI._();

  /// Найти лучший ход для цвета [color] на доске [board].
  static Point? findBestMove(
    Board board,
    StoneColor color,
    Difficulty level, {
    Ruleset ruleset = Ruleset.gomoku,
  }) {
    final candidates = _generateCandidates(board, color, ruleset);
    if (candidates.isEmpty) {
      // доска пуста — ход в центр
      final c = board.size ~/ 2;
      return Point(c, c);
    }
    switch (level) {
      case Difficulty.easy:
        return _easyMove(board, color, candidates, ruleset);
      case Difficulty.medium:
        return _mediumMove(board, color, candidates, ruleset);
      case Difficulty.hard:
        return _hardMove(board, color, candidates, ruleset);
    }
  }

  /// Генерация кандидатов: пустые клетки в радиусе 2 от занятых, без запрещённых
  /// (если чёрные в рэндзю).
  static List<Point> _generateCandidates(
    Board board,
    StoneColor color,
    Ruleset ruleset,
  ) {
    final set = <Point>{};
    if (board.isEmpty) {
      final c = board.size ~/ 2;
      return [Point(c, c)];
    }
    for (final stone in board.occupiedPoints()) {
      for (var dx = -2; dx <= 2; dx++) {
        for (var dy = -2; dy <= 2; dy++) {
          final p = Point(stone.x + dx, stone.y + dy);
          if (p.inBounds(board.size) && board.at(p) == null) {
            set.add(p);
          }
        }
      }
    }
    // фильтруем запрещённые для чёрных в рэндзю
    if (ruleset == Ruleset.renju && color == StoneColor.black) {
      final forbidden = RenjuForbiddenChecker.forbiddenMoves(board);
      return set.where((p) => !forbidden.contains(p)).toList();
    }
    return set.toList();
  }

  /// Быстрая оценка хода: поставить камень, оценить разницу.
  static int _quickScore(Board board, Point p, StoneColor color) {
    final copy = board.copy();
    copy.place(p, color);
    // Проверим, есть ли immediate выигрыш.
    if (PatternDetector.makesFive(copy, p)) {
      return AiEvaluator.fiveScore;
    }
    var s = AiEvaluator.evaluate(copy, color);
    // бонус за центральные клетки
    final center = board.size / 2;
    final dist = (p.x - center).abs() + (p.y - center).abs();
    s += (board.size - dist).toInt();
    return s;
  }

  static Point _easyMove(
    Board board,
    StoneColor color,
    List<Point> candidates,
    Ruleset ruleset,
  ) {
    // Сначала ищем выигрышный ход.
    for (final p in candidates) {
      final copy = board.copy();
      copy.place(p, color);
      if (_wins(copy, p, color, ruleset)) return p;
    }
    // Затем блокируем выигрыш соперника.
    final opp = color.opponent;
    for (final p in candidates) {
      final copy = board.copy();
      copy.place(p, opp);
      if (_wins(copy, p, opp, ruleset)) return p;
    }
    // Иначе — жадный выбор из top-N со случайностью.
    final scored = candidates
        .map((p) => _Candidate(p, _quickScore(board, p, color)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    // Лёгкий уровень: 40% шанс выбрать не лучший ход, а из top-4 случайно.
    final rnd = math.Random();
    if (scored.length > 1 && rnd.nextDouble() < 0.4) {
      final topN = scored.take(math.min(4, scored.length)).toList();
      return topN[rnd.nextInt(topN.length)].point;
    }
    return scored.first.point;
  }

  static Point _mediumMove(
    Board board,
    StoneColor color,
    List<Point> candidates,
    Ruleset ruleset,
  ) {
    // 1. Свой выигрыш.
    for (final p in candidates) {
      final copy = board.copy();
      copy.place(p, color);
      if (_wins(copy, p, color, ruleset)) return p;
    }
    // 2. Блокировка выигрыша соперника.
    final opp = color.opponent;
    for (final p in candidates) {
      final copy = board.copy();
      copy.place(p, opp);
      if (_wins(copy, p, opp, ruleset)) return p;
    }
    // 3. Блокировка открытой четвёрки соперника.
    for (final p in candidates) {
      final copy = board.copy();
      copy.place(p, opp);
      for (final axis in Direction.axes) {
        if (PatternDetector.isOpenFourRun(copy, p, axis)) return p;
      }
    }
    // 4. Жадный с оценкой глубины 2: для каждого своего хода смотрим лучший
    //    ответ соперника и берём максимум (minimax глубины 2).
    final scored = candidates
        .map((p) => _Candidate(p, _quickScore(board, p, color)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(math.min(10, scored.length)).toList();
    var bestScore = -1000000000;
    Point? best = top.first.point;
    for (final c in top) {
      final copy = board.copy();
      copy.place(c.point, color);
      // лучший ответ соперника
      var oppBest = -1000000000;
      final oppCands = _generateCandidates(copy, opp, ruleset);
      final oppScored = oppCands
          .map((p) => _Candidate(p, _quickScore(copy, p, opp)))
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      final oppTop = oppScored.take(math.min(6, oppScored.length)).toList();
      for (final oc in oppTop) {
        final c2 = copy.copy();
        c2.place(oc.point, opp);
        final s = AiEvaluator.evaluate(c2, color);
        if (s > oppBest) oppBest = s; // соперник максимизирует свою выгоду =>
        // для нас это минимум
      }
      // минимакс: наш максимум по минимальному ответу
      final val = -oppBest; // т.к. evaluate для color, соперник уменьшает
      if (val > bestScore) {
        bestScore = val;
        best = c.point;
      }
    }
    return best ?? top.first.point;
  }

  static Point _hardMove(
    Board board,
    StoneColor color,
    List<Point> candidates,
    Ruleset ruleset,
  ) {
    // 1. Немедленный выигрыш.
    for (final p in candidates) {
      final copy = board.copy();
      copy.place(p, color);
      if (_wins(copy, p, color, ruleset)) return p;
    }
    // 2. Блокировка выигрыша соперника.
    final opp = color.opponent;
    for (final p in candidates) {
      final copy = board.copy();
      copy.place(p, opp);
      if (_wins(copy, p, opp, ruleset)) return p;
    }
    // 3. Минимакс с альфа-бета, глубина 4, топ-кандидаты.
    final scored = candidates
        .map((p) => _Candidate(p, _quickScore(board, p, color)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(math.min(12, scored.length)).toList();

    var alpha = -1000000000;
    final beta = 1000000000;
    var bestScore = alpha;
    Point? best = top.first.point;
    for (final c in top) {
      final copy = board.copy();
      copy.place(c.point, color);
      final score = _minimax(
        copy,
        color,
        opp,
        3, // оставшаяся глубина (всего 4: наш ход + 3)
        alpha,
        beta,
        ruleset,
      );
      if (score > bestScore) {
        bestScore = score;
        best = c.point;
        if (score > alpha) alpha = score;
      }
    }
    return best ?? top.first.point;
  }

  /// Минимакс с альфа-бета. [maximizingColor] — цвет, для которого максимизируем.
  static int _minimax(
    Board board,
    StoneColor maximizingColor,
    StoneColor current,
    int depth,
    int alpha,
    int beta,
    Ruleset ruleset,
  ) {
    // Терминальная оценка.
    if (depth == 0) {
      return AiEvaluator.evaluate(board, maximizingColor);
    }
    final cands = _generateCandidates(board, current, ruleset);
    if (cands.isEmpty) {
      return AiEvaluator.evaluate(board, maximizingColor);
    }
    // ограничиваем кандидатов для скорости
    final scored = cands
        .map((p) => _Candidate(p, _quickScore(board, p, current)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(math.min(8, scored.length)).toList();

    final maximizing = current == maximizingColor;
    if (maximizing) {
      var value = -1000000000;
      for (final c in top) {
        // быстрый выигрыш
        final copy = board.copy();
        copy.place(c.point, current);
        if (_wins(copy, c.point, current, ruleset)) {
          return AiEvaluator.fiveScore;
        }
        final child = _minimax(
          copy,
          maximizingColor,
          current.opponent,
          depth - 1,
          alpha,
          beta,
          ruleset,
        );
        if (child > value) value = child;
        if (value > alpha) alpha = value;
        if (alpha >= beta) break; // beta cutoff
      }
      return value;
    } else {
      var value = 1000000000;
      for (final c in top) {
        final copy = board.copy();
        copy.place(c.point, current);
        if (_wins(copy, c.point, current, ruleset)) {
          return -AiEvaluator.fiveScore;
        }
        final child = _minimax(
          copy,
          maximizingColor,
          current.opponent,
          depth - 1,
          alpha,
          beta,
          ruleset,
        );
        if (child < value) value = child;
        if (value < beta) beta = value;
        if (alpha >= beta) break; // alpha cutoff
      }
      return value;
    }
  }

  /// Победа ли ход в [p] цветом [color] по набору правил.
  static bool _wins(Board b, Point p, StoneColor color, Ruleset ruleset) {
    if (ruleset == Ruleset.gomoku) {
      return PatternDetector.runLengthThrough(b, p, Direction(1, 0)) >= 5 ||
          PatternDetector.runLengthThrough(b, p, Direction(0, 1)) >= 5 ||
          PatternDetector.runLengthThrough(b, p, Direction(1, 1)) >= 5 ||
          PatternDetector.runLengthThrough(b, p, Direction(1, -1)) >= 5;
    }
    // renju
    if (color == StoneColor.black) {
      // победа = ровно пять; но также проверим, не запрещён ли ход
      for (final axis in Direction.axes) {
        if (PatternDetector.runLengthThrough(b, p, axis) == 5) return true;
      }
      return false;
    } else {
      for (final axis in Direction.axes) {
        if (PatternDetector.runLengthThrough(b, p, axis) >= 5) return true;
      }
      return false;
    }
  }
}
