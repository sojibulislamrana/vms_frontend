import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/main.dart';

void main() {
  testWidgets('VMS marketing landing and login navigation smoke test', (tester) async {
    // Build the VMS app and trigger an initial frame
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Verify the marketing home screen is presented initially
    expect(find.text('stark fleet'), findsAtLeastNWidgets(1));
    expect(find.text('A clearer view of every mile.'), findsOneWidget);
    expect(find.text('Log in'), findsAtLeastNWidgets(1));

    // Tap the 'Log in' button
    await tester.tap(find.text('Log in').first);
    await tester.pumpAndSettle();

    // Verify navigating to the login screen
    expect(find.text('Sign in to your workspace'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Work email'), findsOneWidget);
  });
}
