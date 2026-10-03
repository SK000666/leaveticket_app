import 'package:flutter_test/flutter_test.dart';
import 'package:leaveticket_app/main.dart';

void main() {
  testWidgets('Leave Ticket App displays correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Check whether the app title is displayed
    expect(find.text('Leave Ticket App'), findsOneWidget);
  });
}
