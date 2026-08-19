import 'package:flutter_test/flutter_test.dart';
import 'package:erbolamm_studio/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ErBolammStudioApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Analizador de Repos'), findsOneWidget);
  });
}
