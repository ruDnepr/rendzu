import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rendzu/core/theme/app_theme.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/point.dart';

/// Виджет доски с объёмными камнями, тёплой деревянной фактурой и лёгким
/// 3D-наклоном. Камни ставятся на пересечения линий.
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
    // если появился новый последний ход — проиграть анимацию постановки
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
        final maxSize =
            math.min(constraints.maxWidth, constraints.maxHeight).clamp(220.0, 520.0);
        final boardPx = maxSize.toDouble();
        final cell = boardPx / widget.board.size;
        final tilt = widget.enableTilt ? -0.06 : 0.0;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // тень под доской
              if (widget.enableTilt)
                Transform.translate(
                  offset: Offset(0, boardPx * 0.42),
                  child: Container(
                    width: boardPx * 0.92,
                    height: boardPx * 0.14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(boardPx * 0.07),
                      color: Colors.black.withOpacity(0.18),
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
                  onTapDown: (details) => _handleTap(details, boardPx, cell),
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
                        patternThrees:
                            widget.showPatterns ? widget.patternThrees : const [],
                        patternFours:
                            widget.showPatterns ? widget.patternFours : const [],
                        hintMove: widget.hintMove,
                      ),
                      child: AnimatedBuilder(
                        animation: _placeCtrl,
                        builder: (context, _) {
                          // лёгкая пульсация последнего камня
                          return const SizedBox.expand();
                        },
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

  void _handleTap(TapDownDetails details, double boardPx, double cell) {
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

  Offset centerOf(Point p) =>
      Offset(cell * (p.x + 0.5), cell * (p.y + 0.5));

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Деревянный фон с градиентом.
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [AppColors.woodLight, AppColors.woodMid, AppColors.woodDark],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // лёгкая текстура: несколько горизонтальных полос
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (i + 0.5) / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
    }

    // 2. Сетка линий.
    final linePaint = Paint()
      ..color = AppColors.woodLine
      ..strokeWidth = board.size <= 9 ? 1.6 : 1.1
      ..style = PaintingStyle.stroke;

    final first = centerOf(const Point(0, 0));
    final last = centerOf(Point(board.size - 1, board.size - 1));
    for (var i = 0; i < board.size; i++) {
      final c = centerOf(Point(i, 0));
      canvas.drawLine(Offset(c.dx, first.dy), Offset(c.dx, last.dy), linePaint);
      final ri = centerOf(Point(0, i)).dy;
      canvas.drawLine(Offset(first.dx, ri), Offset(last.dx, ri), linePaint);
    }

    // 3. Звёздные точки (как в го) — для ориентации.
    final starPaint = Paint()..color = AppColors.woodLine;
    for (final p in _starPoints(board.size)) {
      canvas.drawCircle(centerOf(p), board.size <= 9 ? 3.0 : 3.5, starPaint);
    }

    // 4. Подсветка паттернов (тройки — жёлтые, четвёрки — красные).
    if (patternThrees.isNotEmpty) {
      final p = Paint()
        ..color = AppColors.hintThree
        ..style = PaintingStyle.fill;
      for (final line in patternThrees) {
        for (final pt in line) {
          canvas.drawCircle(centerOf(pt), cell * 0.46, p);
        }
      }
    }
    if (patternFours.isNotEmpty) {
      final p = Paint()
        ..color = AppColors.hintFour
        ..style = PaintingStyle.fill;
      for (final line in patternFours) {
        for (final pt in line) {
          canvas.drawCircle(centerOf(pt), cell * 0.46, p);
        }
      }
    }

    // 5. Подсказка хода.
    if (hintMove != null) {
      final p = Paint()
        ..color = AppColors.hintMove
        ..style = PaintingStyle.fill;
      canvas.drawCircle(centerOf(hintMove!), cell * 0.42, p);
    }

    // 6. Камни.
    for (final pt in board.occupiedPoints()) {
      _drawStone(canvas, centerOf(pt), cell * 0.46, board.at(pt)!,
          isLast: pt == lastMove);
    }

    // 7. Маркеры запрещённых ходов (крестик).
    if (forbiddenHints.isNotEmpty) {
      final paint = Paint()
        ..color = AppColors.forbiddenMarker
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final r = cell * 0.22;
      for (final p in forbiddenHints) {
        final c = centerOf(p);
        canvas.drawLine(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), paint);
        canvas.drawLine(Offset(c.dx - r, c.dy + r), Offset(c.dx + r, c.dy - r), paint);
      }
    }

    // 8. Кольцо последнего хода.
    if (lastMove != null && !winningLine.contains(lastMove)) {
      final ring = Paint()
        ..color = AppColors.lastMoveRing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(centerOf(lastMove!), cell * 0.52, ring);
    }

    // 9. Победная линия — подсветка.
    if (winningLine.length >= 2) {
      final winPaint = Paint()
        ..color = AppColors.sunflower
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.18
        ..strokeCap = StrokeCap.round;
      final start = centerOf(winningLine.first);
      final end = centerOf(winningLine.last);
      canvas.drawLine(start, end, winPaint);
      // обводка камней победной линии
      final ring = Paint()
        ..color = AppColors.sunflower
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (final p in winningLine) {
        canvas.drawCircle(centerOf(p), cell * 0.54, ring);
      }
    }
  }

  void _drawStone(Canvas canvas, Offset center, double radius, StoneColor color,
      {required bool isLast}) {
    // тень
    canvas.drawCircle(
        center.translate(1.5, 2.5),
        radius,
        Paint()..color = Colors.black.withOpacity(0.28));

    // тело камня с радиальным градиентом (блик сверху-слева)
    final grad = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.95,
      colors: color == StoneColor.black
          ? const [AppColors.stoneBlackHi, AppColors.stoneBlack]
          : const [Colors.white, AppColors.stoneWhite, AppColors.stoneWhiteEdge],
      stops: color == StoneColor.black ? const [0.0, 1.0] : const [0.0, 0.7, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
        center,
        radius,
        Paint()..shader = grad.createShader(rect));

    // маленький блик-точка
    final hi = Paint()..color = Colors.white.withOpacity(0.55);
    canvas.drawCircle(center.translate(-radius * 0.35, -radius * 0.35),
        radius * 0.18, hi);
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
