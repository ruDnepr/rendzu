// Дымовой тест приложения: проверяет, что RendzuApp собирается и рендерит
// заставку без исключений.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rendzu/app.dart';

void main() {
  testWidgets('RendzuApp рендерит заставку', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RendzuApp()));
    // один кадр без ожидания навигации
    await tester.pump();
    expect(find.text('Рэндзю'), findsOneWidget);
    expect(find.text('для Дианы'), findsOneWidget);
  });
}
