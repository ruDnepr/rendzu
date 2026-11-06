import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/point.dart';

/// Виджет доски рэндзю: тёплая деревянная фактура (как в шашках), сетка
/// пересечений, звёздные точки, объёмные камни с бликом. Камни ставятся на
/// пересечения и НЕ перекрывают друг друга (радиус < половины клетки).
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.board,
    this.lastMove,
    this.winningLine = const [],
    this.forbiddenHints = const {},
    this.patternThrees = const [],
    this.patternFours = const [],
    this.hintMove,
    this.showForbiddenHints = true,
    this.showPatterns = true,
    this.onTapIntersection,
    this.enableTilt = true,
  });

  final Board board;
  final Point? lastMove;
  final List<Point> winningLine;
  final Set<Point> forbiddenHints;
  final List<List<Point>> patternThrees;
  final List<List<Point>> patternFours;
  final Point? hintMove;
  final bool showForbiddenHints;
  final bool showPatterns;
  final void Function(Point)? onTapIntersection;
  final bool enableTilt;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _placeCtrl;

  @override
  void initState() {
    super.initState();
    _placeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..value = 1.0;
  }

  @override
  void didUpdateWidget(covariant BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastMove != null && widget.lastMove != oldWidget.lastMove) {
      _placeCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = math
            .min(constraints.maxWidth, constraints.maxHeight)
            .clamp(220.0, 520.0);
        final boardPx = maxSize.toDouble();
        final cell = boardPx / widget.board.size;
        final tilt = widget.enableTilt ? -0.05 : 0.0;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.enableTilt)
                Transform.translate(
                  offset: Offset(0, boardPx * 0.42),
                  child: Container(
                    width: boardPx * 0.92,
                    height: boardPx * 0.14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(boardPx * 0.07),
                      color: Colors.black.withOpacity(0.16),
                    ),
                  ),
                ),
              Transform(
                alignment: Alignment.center,
                transform: tilt != 0
                    ? (Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(tilt))
                    : Matrix4.identity(),
                child: GestureDetector(
                  onTapDown: (d) => _handleTap(d, cell),
                  child: SizedBox(
                    width: boardPx,
                    height: boardPx,
                    child: CustomPaint(
                      painter: _BoardPainter(
                        board: widget.board,
                        cell: cell,
                        lastMove: widget.lastMove,
                        winningLine: widget.winningLine,
                        forbiddenHints: widget.showForbiddenHints
                            ? widget.forbiddenHints
                            : const {},
                        patternThrees: widget.showPatterns
                            ? widget.patternThrees
                            : const [],
                        patternFours: widget.showPatterns
                            ? widget.patternFours
                            : const [],
                        hintMove: widget.hintMove,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleTap(TapDownDetails details, double cell) {
    final local = details.localPosition;
    final ix = ((local.dx / cell) - 0.5).round();
    final iy = ((local.dy / cell) - 0.5).round();
    final p = Point(ix, iy);
    if (p.inBounds(widget.board.size)) {
      widget.onTapIntersection?.call(p);
    }
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.cell,
    required this.lastMove,
    required this.winningLine,
    required this.forbiddenHints,
    required this.patternThrees,
    required this.patternFours,
    required this.hintMove,
  });

  final Board board;
  final double cell;
  final Point? lastMove;
  final List<Point> winningLine;
  final Set<Point> forbiddenHints;
  final List<List<Point>> patternThrees;
  final List<List<Point>> patternFours;
  final Point? hintMove;

  // Радиус камня — строго меньше половины клетки, чтобы соседние камни
  // не перекрывали друг друга.
  static const double _stoneRadiusFactor = 0.40;

  Offset centerOf(Point p) => Offset(cell * (p.x + 0.5), cell * (p.y + 0.5));

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Деревянный фон (тёплая палитра как в шашках).
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [boardWoodLight, boardWoodDark],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // лёгкая текстура-полосы
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (i + 0.5) / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
    }

    // 2. Сетка линий (камни на пересечениях).
    final linePaint = Paint()
      ..color = const Color(0xFFF0D9A8)
      ..strokeWidth = board.size <= 9 ? 1.6 : 1.1
      ..style = PaintingStyle.stroke;
    final first = centerOf(const Point(0, 0));
    final last = centerOf(Point(board.size - 1, board.size - 1));
    for (var i = 0; i < board.size; i++) {
      final cx = centerOf(Point(i, 0)).dx;
      canvas.drawLine(Offset(cx, first.dy), Offset(cx, last.dy), linePaint);
      final ry = centerOf(Point(0, i)).dy;
      canvas.drawLine(Offset(first.dx, ry), Offset(last.dx, ry), linePaint);
    }

    // 3. Звёздные точки (как в го).
    final starPaint = Paint()..color = const Color(0xFFF0D9A8);
    for (final p in _starPoints(board.size)) {
      canvas.drawCircle(centerOf(p), board.size <= 9 ? 3.0 : 3.5, starPaint);
    }

    // 4. Подсветка паттернов: тройки (жёлтые), четвёрки (красноватые).
    if (patternThrees.isNotEmpty) {
      final p = Paint()..color = yellow.withOpacity(.35);
      for (final line in patternThrees) {
        for (final pt in line) {
          canvas.drawCircle(centerOf(pt), cell * 0.44, p);
        }
      }
    }
    if (patternFours.isNotEmpty) {
      final p = Paint()..color = const Color(0xFFE27D60).withOpacity(.35);
      for (final line in patternFours) {
        for (final pt in line) {
          canvas.drawCircle(centerOf(pt), cell * 0.44, p);
        }
      }
    }

    // 5. Подсказка хода.
    if (hintMove != null) {
      final p = Paint()..color = purple.withOpacity(.35);
      canvas.drawCircle(centerOf(hintMove!), cell * 0.40, p);
      canvas.drawCircle(
          centerOf(hintMove!), cell * 0.18, Paint()..color = lilac);
    }

    // 6. Камни.
    final stoneR = cell * _stoneRadiusFactor;
    for (final pt in board.occupiedPoints()) {
      _drawStone(canvas, centerOf(pt), stoneR, board.at(pt)!);
    }

    // 7. Маркеры запрещённых ходов (крестик).
    if (forbiddenHints.isNotEmpty) {
      final paint = Paint()
        ..color = const Color(0xFFE27D60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final r = cell * 0.20;
      for (final p in forbiddenHints) {
        final c = centerOf(p);
        canvas.drawLine(
            Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), paint);
        canvas.drawLine(
            Offset(c.dx - r, c.dy + r), Offset(c.dx + r, c.dy - r), paint);
      }
    }

    // 8. Кольцо последнего хода.
    if (lastMove != null && !winningLine.contains(lastMove)) {
      final ring = Paint()
        ..color = yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(centerOf(lastMove!), cell * 0.46, ring);
    }

    // 9. Победная линия — подсветка.
    if (winningLine.length >= 2) {
      final winPaint = Paint()
        ..color = yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.16
        ..strokeCap = StrokeCap.round;
      final start = centerOf(winningLine.first);
      final end = centerOf(winningLine.last);
      canvas.drawLine(start, end, winPaint);
      final ring = Paint()
        ..color = yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (final p in winningLine) {
        canvas.drawCircle(centerOf(p), cell * 0.48, ring);
      }
    }
  }

  void _drawStone(
      Canvas canvas, Offset center, double radius, StoneColor color) {
    // тень
    canvas.drawCircle(
      center.translate(1.5, 2.5),
      radius,
      Paint()..color = Colors.black.withOpacity(0.28),
    );

    // тело камня с радиальным градиентом (блик сверху-слева)
    final grad = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: color == StoneColor.black
          ? const [stoneBlackHi, stoneBlack]
          : const [Colors.white, stoneWhite, stoneWhiteEdge],
      stops: color == StoneColor.black
          ? const [0.0, 1.0]
          : const [0.0, 0.7, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
        center, radius, Paint()..shader = grad.createShader(rect));

    // маленький блик-точка
    final hi = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawCircle(
        center.translate(-radius * 0.35, -radius * 0.35),
        radius * 0.18,
        hi);
  }

  List<Point> _starPoints(int size) {
    if (size == 9) {
      return const [
        Point(2, 2), Point(6, 2), Point(4, 4),
        Point(2, 6), Point(6, 6),
      ];
    }
    if (size == 15) {
      return const [
        Point(3, 3), Point(11, 3), Point(7, 7),
        Point(3, 11), Point(11, 11),
      ];
    }
    return const [];
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      old.board != board ||
      old.lastMove != lastMove ||
      old.winningLine != winningLine ||
      old.forbiddenHints != forbiddenHints ||
      old.hintMove != hintMove;
}
