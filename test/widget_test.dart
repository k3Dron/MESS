// Basic smoke test for the Mezz app.
import 'package:flutter_test/flutter_test.dart';
import 'package:mezz/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MezzApp());
    // App should render without crashing.
    expect(find.text('Mezz'), findsAny);
  });
}
