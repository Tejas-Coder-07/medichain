import 'package:flutter_test/flutter_test.dart';
import 'package:medichain_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MediChainApp());
  });
}
