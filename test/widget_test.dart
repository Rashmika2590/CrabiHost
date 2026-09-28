import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crabihost/main.dart';

void main() {
  testWidgets('CrabigoHostApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CrabigoHostApp(),
      ),
    );
    expect(find.byType(CrabigoHostApp), findsOneWidget);
  });
}
