import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_nasi_goreng/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KasirApp());
    expect(find.byType(KasirApp), findsOneWidget);
  });
}
