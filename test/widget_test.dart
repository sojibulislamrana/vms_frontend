import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/main.dart';

void main() {
  testWidgets('VMS application login and shell smoke test', (tester) async {
    // Build the VMS app and trigger an initial frame
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Verify the login screen is presented initially
    expect(find.text('Vehicle Management System'), findsOneWidget);
    expect(find.text('Sign In to Fleet Console'), findsOneWidget);
    expect(find.text('Use Stark Demo Credentials'), findsOneWidget);

    // Tap the 'Sign In to Fleet Console' button
    await tester.tap(find.text('Sign In to Fleet Console'));
    await tester.pumpAndSettle();

    // Verify successful authentication lands in the Fleet Directory screen
    expect(find.text('Fleet Directory'), findsOneWidget);
    expect(find.text('TOTAL FLEET'), findsOneWidget);
    expect(find.text('Register Vehicle'), findsAtLeastNWidgets(1));

    // Tap on the navbar logo / brand to go to Home (Dashboard)
    await tester.tap(find.byTooltip('Go to Home (Dashboard)'));
    await tester.pumpAndSettle();

    // Verify Home / Dashboard is presented with executive overview
    expect(find.text('Welcome back, Tony Stark'), findsOneWidget);
    expect(find.text('Fleet Operational Rate'), findsOneWidget);
  });
}
