// Basic widget test for Trip Mate app
import 'package:flutter_test/flutter_test.dart';
import 'package:trip_mate/app.dart';

void main() {
  testWidgets('App loads Get Started screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify that Get Started screen is shown
    expect(find.text('Trip Mate'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
