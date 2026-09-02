import 'package:flutter_test/flutter_test.dart';
import 'package:sabimove/main.dart';

void main() {
  testWidgets('SabiMove inicia corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const SabiMoveApp());

    expect(find.text('SabiMove'), findsOneWidget);
    expect(find.text('by Sabino AI'), findsOneWidget);
  });
}
