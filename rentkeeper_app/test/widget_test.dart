import 'package:flutter_test/flutter_test.dart';
import 'package:rentkeeper_app/main.dart';

void main() {
  testWidgets('RentKeeper app renders dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RentKeeperApp());
    expect(find.text('Al-Rehman Rentals'), findsOneWidget);
    expect(find.text('LAHORE'), findsOneWidget);
    expect(find.text('Total Equipment'), findsOneWidget);
  });
}
