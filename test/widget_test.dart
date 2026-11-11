import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:creative_os/main.dart';

void main() {
  testWidgets('EtoleApp initial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EtoleApp()));
    expect(find.byType(EtoleApp), findsOneWidget);
  });
}
