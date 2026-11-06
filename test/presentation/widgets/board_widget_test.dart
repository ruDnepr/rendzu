import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/domain/models/board.dart';
import 'package:rendzu/domain/models/point.dart';
import 'package:rendzu/presentation/widgets/board_widget.dart';

void main() {
  testWidgets('BoardWidget рендерится с пустой доской', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: BoardWidget(
                board: Board(9),
                onTapIntersection: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(BoardWidget), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('BoardWidget показывает камни и последний ход', (tester) async {
    final board = Board(9);
    board.place(const Point(4, 4), StoneColor.black);
    board.place(const Point(5, 4), StoneColor.white);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: BoardWidget(
                board: board,
                lastMove: const Point(5, 4),
                onTapIntersection: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(BoardWidget), findsOneWidget);
  });

  testWidgets('BoardWidget обрабатывает тап по пересечению', (tester) async {
    Point? tapped;
    final board = Board(9);
    board.place(const Point(4, 4), StoneColor.black);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 360,
              child: BoardWidget(
                board: board,
                enableTilt: false,
                onTapIntersection: (p) => tapped = p,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Тапнем в центр доски (примерно (4,4)).
    await tester.tap(find.byType(BoardWidget));
    await tester.pump();
    // Тап должен попасть в какую-то точку на доске.
    expect(tapped, isNotNull);
    expect(tapped!.inBounds(9), isTrue);
  });

  testWidgets('BoardWidget показывает маркеры запрещённых ходов',
      (tester) async {
    final board = Board(9);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: BoardWidget(
                board: board,
                forbiddenHints: {const Point(3, 3)},
                showForbiddenHints: true,
                onTapIntersection: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(BoardWidget), findsOneWidget);
  });
}
