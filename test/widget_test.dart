import 'package:flutter_test/flutter_test.dart';
import 'package:seatfirst/main.dart';

void main() {
  testWidgets('SeatFirst app loads search screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SeatFirstApp());
    await tester.pump();

    expect(find.text('SeatFirst'), findsOneWidget);
    expect(find.text('Find your seat. Then your bus.'), findsOneWidget);
    expect(find.text('Find Seats →'), findsOneWidget);
  });
}
